"""One-shot prompt-optimization check for Qwen3-0.6B via llama-server.

Tests exactly 5 fixed cases (v3 prompt with date/time/reminder/type rules and
few-shot). Does not expand the dataset. Compares against hand labels.
"""
from __future__ import annotations

import io
import json
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "out"
PROMPT_PATH = ROOT / "prompts" / "extract_v3.txt"
SCHEMA_PATH = ROOT / "datasets" / "schema" / "task.schema.json"
MODEL = ROOT / "models" / "Qwen3-0.6B-Q4_K_M.gguf"
PORT = 18232
BASE = f"http://127.0.0.1:{PORT}"

CASES = [
    {
        "id": "P1",
        "input": "11.1下午三点到五点四十上英语课，提前半小时和一小时通知我，备注一下在301教室",
        "expected": {
            "title": "英语课", "date": "2026-11-01", "startTime": "15:00",
            "endTime": "17:40", "taskType": "schedule", "todoTimeMode": "timeBlock",
            "reminders": [3600, 1800], "note": "301教室",
        },
    },
    {
        "id": "P2",
        "input": "明天下午三点开会",
        "expected": {
            "title": "开会", "date": "2026-10-21", "startTime": "15:00",
            "endTime": None, "taskType": "schedule", "todoTimeMode": "timeBlock",
            "reminders": [], "note": None,
        },
    },
    {
        "id": "P3",
        "input": "周五晚上八点前交作业，提前一天提醒",
        "expected": {
            "title": "交作业", "date": "2026-10-23", "startTime": None,
            "endTime": "20:00", "taskType": "todo", "todoTimeMode": "deadline",
            "reminders": [86400], "note": None,
        },
    },
    {
        "id": "P4",
        "input": "记得买牛奶",
        "expected": {
            "title": "买牛奶", "date": None, "startTime": None,
            "endTime": None, "taskType": "todo", "todoTimeMode": "noTime",
            "reminders": [], "note": None,
        },
    },
    {
        "id": "P5",
        "input": "下个月3号下午两点去医院，备注带上检查报告",
        "expected": {
            "title": "去医院", "date": "2026-11-03", "startTime": "14:00",
            "endTime": None, "taskType": "schedule", "todoTimeMode": "timeBlock",
            "reminders": [], "note": "带上检查报告",
        },
    },
]

FIELDS = [
    ("title", "title"), ("date", "date"), ("startTime", "startTime"),
    ("endTime", "endTime"), ("reminders", "reminderOffsetsSeconds"),
    ("note", "note"), ("taskType", "taskType"), ("todoTimeMode", "todoTimeMode"),
]
CRITICAL = ["title", "date", "startTime", "endTime", "reminders", "note"]


def start_server() -> subprocess.Popen:
    server = ROOT / "tools" / "llama-server.exe"
    log = (OUT_DIR / "server_v3.log").open("w", encoding="utf-8")
    proc = subprocess.Popen(
        [
            str(server), "-m", str(MODEL), "-c", "2048", "--temp", "0",
            "-ngl", "0", "--no-jinja", "--host", "127.0.0.1", "--port", str(PORT),
        ],
        stdout=log, stderr=subprocess.STDOUT, cwd=str(ROOT),
    )
    for _ in range(60):
        time.sleep(1)
        try:
            with urllib.request.urlopen(f"{BASE}/health", timeout=2):
                return proc
        except Exception:
            continue
    raise SystemExit("server did not become healthy")


def score(expected: dict, parsed) -> dict:
    if parsed is None:
        return {"json_ok": False, "full": False, "fields": {}}
    fields = {
        "title": (parsed.get("title") or "").strip() == (expected.get("title") or ""),
        "date": parsed.get("date") == expected.get("date"),
        "startTime": parsed.get("startTime") == expected.get("startTime"),
        "endTime": parsed.get("endTime") == expected.get("endTime"),
        "reminders": sorted(parsed.get("reminderOffsetsSeconds") or [])
        == sorted(expected.get("reminders") or []),
        "note": (parsed.get("note") or None) == (expected.get("note") or None),
        "taskType": parsed.get("taskType") == expected.get("taskType"),
        "todoTimeMode": parsed.get("todoTimeMode") == expected.get("todoTimeMode"),
    }
    full = all(fields[k] for k in CRITICAL)
    hallucinated = expected.get("date") is None and parsed.get("date") is not None
    return {"json_ok": True, "full": full, "hallucinated": hallucinated, "fields": fields}


def main() -> int:
    template = PROMPT_PATH.read_text(encoding="utf-8")
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    proc = start_server()
    results = []
    try:
        for case in CASES:
            prompt = template.replace("{input}", case["input"])
            payload = {
                "prompt": prompt, "n_predict": 256, "temperature": 0.0,
                "json_schema": schema, "cache_prompt": False,
            }
            request = urllib.request.Request(
                f"{BASE}/completion",
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"}, method="POST",
            )
            started = time.perf_counter()
            with urllib.request.urlopen(request, timeout=300) as response:
                body = json.loads(response.read().decode("utf-8", errors="replace"))
            elapsed_ms = round((time.perf_counter() - started) * 1000, 1)

            content = body.get("content", "")
            try:
                parsed = json.loads(content)
            except json.JSONDecodeError:
                parsed = None
            row = score(case["expected"], parsed)
            row.update(
                {
                    "id": case["id"], "input": case["input"],
                    "expected": case["expected"], "raw": content,
                    "parsed": parsed, "elapsed_ms": elapsed_ms,
                    "prompt_tokens": body.get("timings", {}).get("prompt_n"),
                    "gen_tokens": body.get("timings", {}).get("predicted_n"),
                }
            )
            results.append(row)
            print(
                f"[{case['id']}] {elapsed_ms}ms prompt_tok={row['prompt_tokens']} "
                f"gen_tok={row['gen_tokens']} json={row['json_ok']} full={row['full']}"
            )
            print("  raw:", content)
    finally:
        proc.terminate()

    n = len(results)
    summary = {
        "prompt_version": "extract_v3",
        "n": n,
        "json_ok": round(sum(1 for r in results if r["json_ok"]) / n * 100, 1),
        "full": round(sum(1 for r in results if r["full"]) / n * 100, 1),
        "hallucinated_date": sum(1 for r in results if r.get("hallucinated")),
        "latency_p50_ms": sorted(r["elapsed_ms"] for r in results)[n // 2],
        "fields": {},
    }
    for key, _ in FIELDS:
        summary["fields"][key] = round(
            sum(1 for r in results if r["fields"].get(key)) / n * 100, 1
        )
    (OUT_DIR / "pc_qwen3-0.6b_v3_5cases.json").write_text(
        json.dumps({"summary": summary, "results": results},
                   ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print("\n=== SUMMARY ===")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
