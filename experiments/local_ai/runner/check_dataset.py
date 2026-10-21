import json
from collections import Counter

with open("datasets/cases.jsonl", encoding="utf-8") as handle:
    items = [json.loads(line) for line in handle if line.strip()]

print("total", len(items))
print(dict(Counter(item["group"] for item in items)))
print("smoke", sum(1 for item in items if item.get("smoke")))
