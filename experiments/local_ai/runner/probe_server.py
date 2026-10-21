import json
import urllib.request

schema = json.loads(open("datasets/schema/task.schema.json", encoding="utf-8").read())
payload = {
    "prompt": (
        "你是日程识别器。只输出 JSON，不要解释和思考过程。\n"
        "用户输入：明天下午三点开会\n"
        "JSON："
    ),
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
with urllib.request.urlopen(request, timeout=300) as response:
    print(response.read().decode("utf-8", errors="replace"))
