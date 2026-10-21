"""Run extraction through official llama-cli (b11756) + --json-schema.

llama-cpp-python had no cp310 wheel in this environment and nmake is missing,
so per the authorized fallback we use the prebuilt Windows CPU CLI instead of
compiling from source.
"""
from __future__ import annotations

import argparse
import json
import os
import statistics
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import psutil

from common import DATASETS_DIR, MODELS, OUT_DIR, ROOT

PROMPT_PATH = ROOT / "prompts" / "extract_v2.txt"
PROMPT_PATH_CLI = PROMPT_PATH
SCHEMA_PATH = ROOT / "datasets" / "schema" / "task.schema.json"
CLI_VERSION = "b11756"
WEEKDAYS = ["一", "二", "三", "四", "五", "六", "日"]


def cli_path() -> Path:
    candidates = [
        ROOT / "tools" / "llama-cli.exe",
        ROOT / "tools" / "build" / "bin" / "llama-cli.exe",
    ]
    for path in candidates:
        if path.exists():
            return path
    raise SystemExit("llama-cli.exe not found under experiments/local_ai/tools")


def load_cases() -> list[dict]:
    cases = []
    with (DATASETS_DIR / "cases.jsonl").open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                cases.append(json.loads(line))
    return cases


def build_prompt(template: str, case: dict) -> str:
    import datetime

    weekday = WEEKDAYS[datetime.date.fromisoformat(case["referenceDate"]).weekday()]
    return (
        template.replace("{reference_date}", case["referenceDate"])
        .replace("{reference_weekday}", weekday)
        .replace("{input}", case["input"])
    )


def rss_mib() -> float:
    return round(psutil.Process().memory_info().rss / (1024 * 1024), 1)


def parse_json_lenient(text: str):
    cleaned = text.strip()
    if "```" in cleaned:
        for part in cleaned.split("```"):
            candidate = part.strip()
            if candidate.startswith("json"):
                candidate = candidate[4:].strip()
            if candidate.startswith("{"):
                cleaned = candidate
                break
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return None, False
    # Skip the llama-cli banner/echo: the model JSON is the last {...} block.
    gen_marker = cleaned.rfind("JSON")
    gen_start = cleaned.find("{", gen_marker if gen_marker != -1 else start)
    if gen_start != -1 and gen_start < end:
        start = gen_start
    try:
        return json.loads(cleaned[start : end + 1]), True
    except json.JSONDecodeError:
        return None, False


def run_model(model_key: str, smoke: bool, max_tokens: int, n_ctx: int) -> Path:
    spec = MODELS[model_key]
    if not spec.local_path.exists():
        raise SystemExit(f"model missing: {spec.local_path} (run download.py)")

    cases = load_cases()
    if smoke:
        cases = [c for c in cases if c.get("smoke")]
    template = PROMPT_PATH.read_text(encoding="utf-8")

    results: list[dict] = []
    rss_before = rss_mib()

    # Cold start includes process spawn + model load; CLI has no persistent
    # session here, so every call is measured end-to-end. Hot-start
    # (server KV reuse) is covered separately on Android if PC is promising.
    for index, case in enumerate(cases):
        prompt_dir = ROOT / "out" / "_prompts"
        prompt_dir.mkdir(parents=True, exist_ok=True)
        prompt_path = prompt_dir / f"{case['id']}.txt"
        prompt_path.write_text(build_prompt(template, case), encoding="utf-8")
        command = [
            str(cli_path()),
            "-m",
            str(spec.local_path),
            "-f",
            prompt_path,
            "--no-mmproj",
            "--threads",
            str(os.cpu_count() or 8),
            "-c",
            str(n_ctx),
            "-n",
            str(max_tokens),
            "--temp",
            "0.0",
            "--top-k",
            "20",
            "--top-p",
            "0.8",
            "--repeat-penalty",
            "1.05",
            "--reasoning",
            "off" if not spec.enable_thinking else "auto",
            "--no-jinja",
            "--json-schema",
            SCHEMA_PATH.read_text(encoding="utf-8"),
            "--no-display-prompt",
            "--simple-io",
            "-ngl",
            "0",
        ]
        env = dict(os.environ)
        env["PYTHONIOENCODING"] = "utf-8"
        env["OMP_NUM_THREADS"] = env.get("OMP_NUM_THREADS", str(os.cpu_count() or 8))
        started = time.perf_counter()
        completed = subprocess.run(
            command,
            capture_output=True,
            timeout=600,
            cwd=str(ROOT),
            env=env,
        )
        try:
            raw = completed.stdout.decode("utf-8", errors="replace").strip()
            err = completed.stderr.decode("utf-8", errors="replace").strip()
        except Exception:
            raw, err = "", ""
        if completed.returncode != 0:
            raw = (raw + "\n[stderr]\n" + err[-2000:]).strip()
        elapsed_ms = round((time.perf_counter() - started) * 1000, 1)
        obj, json_ok = parse_json_lenient(raw)
        results.append(
            {
                "id": case["id"],
                "group": case["group"],
                "input": case["input"],
                "expected": case["expected"],
                "raw": raw[:4000],
                "parsed": obj,
                "json_ok": json_ok and completed.returncode == 0,
                "elapsed_ms": elapsed_ms,
            }
        )
        print(f"[{index + 1}/{len(cases)}] {case['id']} {elapsed_ms}ms json={json_ok}")

    latencies = [r["elapsed_ms"] for r in results]
    payload = {
        "model": model_key,
        "repo": spec.repo,
        "filename": spec.filename,
        "model_bytes": spec.size,
        "license": spec.license,
        "runtime": f"llama.cpp {CLI_VERSION} official Windows CPU CLI",
        "enable_thinking": spec.enable_thinking,
        "smoke": smoke,
        "n_ctx": n_ctx,
        "max_tokens": max_tokens,
        "note": "CLI spawns a fresh process per case: every call is cold-load end-to-end.",
        "rss_before_mib": rss_before,
        "cold_load_ms": None,
        "warm_latency_p50_ms": _median(latencies),
        "warm_latency_p95_ms": _p95(latencies),
        "cases": results,
    }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    suffix = "smoke" if smoke else "full"
    out_path = OUT_DIR / f"pc_{model_key}_{suffix}.json"
    out_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"[written] {out_path}")
    return out_path


def _median(values: list[float]) -> float:
    return round(statistics.median(values), 1) if values else 0.0


def _p95(values: list[float]) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = min(len(ordered) - 1, int(round(0.95 * (len(ordered) - 1))))
    return round(ordered[index], 1)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", choices=list(MODELS), required=True)
    parser.add_argument("--smoke", action="store_true")
    parser.add_argument("--max-tokens", type=int, default=256)
    parser.add_argument("--n-ctx", type=int, default=2048)
    args = parser.parse_args()
    run_model(args.model, args.smoke, args.max_tokens, args.n_ctx)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
