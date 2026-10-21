"""Re-score the EXISTING 12-case smoke logs with a fixed extractor.

Only reads out/pc_qwen3-0.6b_smoke.json and writes a NEW sidecar file
out/pc_qwen3-0.6b_smoke_RESCUE.json. Does not rerun the batch.
"""
from __future__ import annotations

import io
import json
import sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "out"
SRC = OUT_DIR / "pc_qwen3-0.6b_smoke.json"
DST = OUT_DIR / "pc_qwen3-0.6b_smoke_RESCUE.json"


def extract_model_json(text: str):
    """Find the last top-level {...} block after the echoed JSON marker."""
    if not text:
        return None, False
    marker = text.rfind("JSON")
    start_from = marker + 4 if marker != -1 else 0
    text = text[start_from:]
    best = None
    depth = 0
    in_string = False
    escaped = False
    start = -1
    for index, char in enumerate(text):
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            if depth == 0:
                start = index
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0 and start != -1:
                candidate = text[start : index + 1]
                try:
                    best = json.loads(candidate)
                except json.JSONDecodeError:
                    best = None
    return (best, best is not None)


def score_case(expected: dict, parsed) -> dict:
    if parsed is None:
        return {"full": False, "json_ok": False, "fields": {}}
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
    full = all(
        [
            fields["title"],
            fields["date"],
            fields["startTime"],
            fields["endTime"],
            fields["reminders"],
            fields["note"],
        ]
    )
    hallucinated = expected.get("date") is None and parsed.get("date") is not None
    if expected.get("needsConfirmation") and parsed.get("date") is not None:
        full = False
    return {"full": full, "json_ok": True, "hallucinated": hallucinated, "fields": fields}


def main() -> int:
    payload = json.loads(SRC.read_text(encoding="utf-8"))
    n = len(payload["cases"])
    rows = []
    for case in payload["cases"]:
        parsed, ok = extract_model_json(case.get("raw", ""))
        case["rescue_parsed"] = parsed
        case["rescue_json_ok"] = ok
        row = score_case(case["expected"], parsed)
        case["rescue_score"] = row
        rows.append(row)

    summary = {
        "source_file": SRC.name,
        "n": n,
        "rescue_json_ok": round(sum(1 for r in rows if r["json_ok"]) / n * 100, 1),
        "rescue_full": round(sum(1 for r in rows if r["full"]) / n * 100, 1),
        "rescue_hallucinated_date": round(
            sum(1 for r in rows if r["hallucinated"]) / n * 100, 1
        ),
        "fields": {},
    }
    field_keys = ["title", "date", "startTime", "endTime", "reminders", "note",
                  "taskType", "todoTimeMode"]
    for key in field_keys:
        hits = sum(1 for r in rows if r["fields"].get(key))
        summary["fields"][key] = round(hits / n * 100, 1)

    DST.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    for case in payload["cases"]:
        parsed = case.get("rescue_parsed") or {}
        print(
            case["id"], "json=", case["rescue_json_ok"],
            "full=", case["rescue_score"]["full"],
            "parsed=", json.dumps(parsed, ensure_ascii=False),
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
