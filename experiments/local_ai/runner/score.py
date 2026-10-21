"""Score model outputs against hand-labeled expectations.

No rule parser code is imported here: scoring is pure data comparison.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "out"

FIELD_WEIGHTS = ["title", "date", "startTime", "endTime", "reminders_same"]


def same_reminders(a, b) -> bool:
    return sorted(a or []) == sorted(b or [])


def score_case(case: dict) -> dict:
    expected = case["expected"]
    parsed = case.get("parsed")
    needs_confirmation = bool(expected.get("needsConfirmation", False))

    if not case.get("json_ok") or parsed is None:
        return {
            "full": False,
            "json_ok": False,
            "hallucinated_date": False,
            "fields": {},
        }

    fields = {
        "title": (parsed.get("title") or "").strip() == (expected.get("title") or ""),
        "date": parsed.get("date") == expected.get("date"),
        "startTime": parsed.get("startTime") == expected.get("startTime"),
        "endTime": parsed.get("endTime") == expected.get("endTime"),
        "reminders_same": same_reminders(
            parsed.get("reminderOffsetsSeconds"), expected.get("reminders")
        ),
        "note": (parsed.get("note") or None) == (expected.get("note") or None),
        "taskType": parsed.get("taskType") == expected.get("taskType"),
        "todoTimeMode": parsed.get("todoTimeMode") == expected.get("todoTimeMode"),
    }
    full = all([fields["title"], fields["date"], fields["startTime"],
                fields["endTime"], fields["reminders_same"], fields["note"]])

    # Date hallucination: expected null date but model emitted a date.
    hallucinated = expected.get("date") is None and parsed.get("date") is not None
    # If the case itself requires confirmation (date unknown), a non-null date is also a failure.
    if needs_confirmation and parsed.get("date") is not None:
        full = False

    return {"full": full, "json_ok": True, "hallucinated_date": hallucinated, "fields": fields}


def score_file(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    rows = [score_case(c) for c in payload["cases"]]
    n = len(rows)
    field_hits: dict[str, int] = {}
    for row in rows:
        for key, value in row["fields"].items():
            field_hits[key] = field_hits.get(key, 0) + (1 if value else 0)
    field_rates = {k: round(v / n * 100, 1) for k, v in field_hits.items()}
    summary = {
        "file": path.name,
        "n": n,
        "json_ok": round(sum(1 for r in rows if r["json_ok"]) / n * 100, 1),
        "full": round(sum(1 for r in rows if r["full"]) / n * 100, 1),
        "hallucinated_date": round(
            sum(1 for r in rows if r["hallucinated_date"]) / n * 100, 1
        ),
        "fields": field_rates,
        "cold_load_ms": payload.get("cold_load_ms"),
        "warm_latency_p50_ms": payload.get("warm_latency_p50_ms"),
        "warm_latency_p95_ms": payload.get("warm_latency_p95_ms"),
        "peak_working_set_mib": payload.get("peak_working_set_mib"),
        "peak_rss_mib": payload.get("peak_rss_mib"),
        "rss_after_release_mib": payload.get("rss_after_release_mib"),
    }
    # Attach per-case results for failure review.
    for case, row in zip(payload["cases"], rows):
        case["score"] = row
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return summary


def main() -> int:
    files = sorted(OUT_DIR.glob("pc_*_full.json")) or sorted(OUT_DIR.glob("pc_*.json"))
    summaries = [score_file(path) for path in files]
    print(json.dumps(summaries, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
