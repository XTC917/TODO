import io
import json
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

path, *wanted = sys.argv[1:]
payload = json.loads(open(path, encoding="utf-8").read())
for case in payload["cases"]:
    if wanted and case["id"] not in wanted:
        continue
    print("=" * 80)
    print(case["id"], case["input"])
    print("-- raw --")
    print(repr(case["raw"])[:3000])
