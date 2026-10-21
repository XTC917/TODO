"""Run GGUF extraction over the dataset and record timing + memory.

Windows-specific peak working set uses ctypes GetProcessMemoryInfo; on other
platforms we fall back to psutil RSS (clearly marked in output).
"""
from __future__ import annotations

import argparse
import ctypes
import ctypes.wintypes as wt
import json
import statistics
import sys
import time
from pathlib import Path

import psutil

from common import DATASETS_DIR, MODELS, OUT_DIR, ROOT

PROMPT_PATH = ROOT / "prompts" / "extract_v1.txt"
SCHEMA_PATH = ROOT / "datasets" / "schema" / "task.schema.json"

WEEKDAYS = ["一", "二", "三", "四", "五", "六", "日"]


def load_cases() -> list[dict]:
    cases = []
    with (DATASETS_DIR / "cases.jsonl").open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                cases.append(json.loads(line))
    return cases


def reference_label(reference_date: str) -> str:
    import datetime

    day = datetime.date.fromisoformat(reference_date)
    return WEEKDAYS[day.weekday()]


class PeakMemory:
    """Tracks peak memory of the current process during a block."""

    def __init__(self) -> None:
        self.process = psutil.Process()
        self.peak_rss = 0
        self.peak_ws = 0
        self._win = sys.platform.startswith("win")

    def sample(self) -> None:
        rss = self.process.memory_info().rss
        self.peak_rss = max(self.peak_rss, rss)
        if self._win:
            self.peak_ws = max(self.peak_ws, _windows_peak_working_set(self.process.pid))

    def reset(self) -> None:
        self.peak_rss = 0
        self.peak_ws = 0

    def rss_mib(self) -> float:
        return round(self.peak_rss / (1024 * 1024), 1)

    def ws_mib(self) -> float | None:
        if not self._win or self.peak_ws == 0:
            return None
        return round(self.peak_ws / (1024 * 1024), 1)


class PROCESS_MEMORY_COUNTERS(ctypes.Structure):
    _fields_ = [
        ("cb", wt.DWORD),
        ("PageFaultCount", wt.DWORD),
        ("PeakWorkingSetSize", ctypes.c_size_t),
        ("WorkingSetSize", ctypes.c_size_t),
        ("QuotaPeakPagedPoolUsage", ctypes.c_size_t),
        ("QuotaPagedPoolUsage", ctypes.c_size_t),
        ("QuotaPeakNonPagedPoolUsage", ctypes.c_size_t),
        ("QuotaNonPagedPoolUsage", ctypes.c_size_t),
        ("PagefileUsage", ctypes.c_size_t),
        ("PeakPagefileUsage", ctypes.c_size_t),
    ]


def _windows_peak_working_set(pid: int) -> int:
    counters = PROCESS_MEMORY_COUNTERS()
    counters.cb = ctypes.sizeof(counters)
    handle = ctypes.windll.kernel32.OpenProcess(0x1000 | 0x0400, False, pid)
    if not handle:
        return 0
    try:
        ok = ctypes.windll.psapi.GetProcessMemoryInfo(
            handle, ctypes.byref(counters), counters.cb
        )
        return counters.PeakWorkingSetSize if ok else 0
    finally:
        ctypes.windll.kernel32.CloseHandle(handle)


def current_rss_mib() -> float:
    return round(psutil.Process().memory_info().rss / (1024 * 1024), 1)


def build_prompt(template: str, case: dict) -> str:
    return (
        template.replace("{reference_date}", case["referenceDate"])
        .replace("{reference_weekday}", reference_label(case["referenceDate"]))
        .replace("{input}", case["input"])
    )


def parse_json_lenient(text: str):
    """Strip code fences / think blocks, then return (obj, json_ok)."""
    cleaned = text.strip()
    if "```" in cleaned:
        parts = cleaned.split("```")
        for part in parts:
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
    snippet = cleaned[start : end + 1]
    try:
        return json.loads(snippet), True
    except json.JSONDecodeError:
        return None, False


def run_model(model_key: str, smoke: bool, max_tokens: int, n_ctx: int) -> Path:
    from llama_cpp import Llama  # imported lazily so --help works without it

    spec = MODELS[model_key]
    if not spec.local_path.exists():
        raise SystemExit(f"model missing: {spec.local_path} (run download.py)")

    cases = load_cases()
    if smoke:
        cases = [c for c in cases if c.get("smoke")]
    template = PROMPT_PATH.read_text(encoding="utf-8")
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

    results: list[dict] = []
    mem = PeakMemory()

    # ---- cold start: process RSS before load
    rss_before = current_rss_mib()

    load_start = time.perf_counter()
    llm = Llama(
        model_path=str(spec.local_path),
        n_ctx=n_ctx,
        n_threads=None,
        n_gpu_layers=0,
        verbose=False,
        seed=7,
    )
    load_ms = round((time.perf_counter() - load_start) * 1000, 1)
    rss_after_load = current_rss_mib()
    mem.sample()

    for case in cases:
        prompt = build_prompt(template, case)
        t0 = time.perf_counter()
        response = llm.create_chat_completion(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=max_tokens,
            temperature=0.0,
            top_p=0.8,
            top_k=20,
            repeat_penalty=1.05,
            response_format={"type": "json_object", "schema": schema},
            chat_template_kwargs={"enable_thinking": spec.enable_thinking},
        )
        elapsed_ms = round((time.perf_counter() - t0) * 1000, 1)
        mem.sample()

        raw = response["choices"][0]["message"]["content"] or ""
        completion_tokens = response.get("usage", {}).get("completion_tokens")
        obj, json_ok = parse_json_lenient(raw)

        results.append(
            {
                "id": case["id"],
                "group": case["group"],
                "input": case["input"],
                "expected": case["expected"],
                "raw": raw,
                "parsed": obj,
                "json_ok": json_ok,
                "elapsed_ms": elapsed_ms,
                "completion_tokens": completion_tokens,
                "prompt_tokens": response.get("usage", {}).get("prompt_tokens"),
            }
        )

    # ---- release
    del llm
    import gc

    gc.collect()
    time.sleep(0.5)
    rss_after_release = current_rss_mib()

    peak_ws = mem.ws_mib()
    payload = {
        "model": model_key,
        "repo": spec.repo,
        "filename": spec.filename,
        "model_bytes": spec.size,
        "license": spec.license,
        "enable_thinking": spec.enable_thinking,
        "smoke": smoke,
        "n_ctx": n_ctx,
        "max_tokens": max_tokens,
        "cold_load_ms": load_ms,
        "rss_before_mib": rss_before,
        "rss_after_load_mib": rss_after_load,
        "peak_rss_mib": mem.rss_mib(),
        "peak_working_set_mib": peak_ws,
        "rss_after_release_mib": rss_after_release,
        "warm_latency_p50_ms": _p50([r["elapsed_ms"] for r in results]),
        "warm_latency_p95_ms": _p95([r["elapsed_ms"] for r in results]),
        "cases": results,
    }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    suffix = "smoke" if smoke else "full"
    out_path = OUT_DIR / f"pc_{model_key}_{suffix}.json"
    out_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"[written] {out_path}")
    print(
        f"load={load_ms}ms p50={payload['warm_latency_p50_ms']}ms "
        f"p95={payload['warm_latency_p95_ms']}ms peak_ws={peak_ws}MiB "
        f"rss_release={rss_after_release}MiB"
    )
    return out_path


def _p50(values: list[float]) -> float:
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
