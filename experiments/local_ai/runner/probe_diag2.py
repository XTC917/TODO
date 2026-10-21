import json
import time
import urllib.request

schema = json.loads(open("datasets/schema/task.schema.json", encoding="utf-8").read())

CASES = [
    ("diag-A01", "你是日程识别器。只输出 JSON，不要解释和思考过程。\n用户输入：11.1下午三点到五点四十上英语课，提前半小时和一小时通知我，备注一下在301教室\nJSON："),
    ("diag-B01", "你是日程识别器。只输出 JSON，不要解释和思考过程。\n用户输入：明天下午三点开会\nJSON："),
]


def call(label, prompt):
    payload = {
        "prompt": prompt,
        "n_predict": 128,
        "temperature": 0.0,
        "json_schema": schema,
    }
    request = urllib.request.Request(
        "http://127.0.0.1:18231/completion",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    started = time.perf_counter()
    with urllib.request.urlopen(request, timeout=300) as response:
        body = json.loads(response.read().decode("utf-8", errors="replace"))
    elapsed_ms = round((time.perf_counter() - started) * 1000, 1)
    print(label, "elapsed_ms=", elapsed_ms)
    print(body["content"])
    print("timings:", body["timings"])
    return elapsed_ms


for label, prompt in CASES:
    call(label, prompt)
