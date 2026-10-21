# Local AI experiment (Stage 2B-A) — JUJU Schedule

独立实验目录，用于评估本地小模型（Qwen3-0.6B / Qwen2.5-0.5B GGUF）
是否值得接入 JUJU 的 AI 智能识别。

## 原则

- 不修改 `lib/`、`android/` 等正式工程代码与配置。
- 模型文件（`models/`）、实验输出（`out/`）、虚拟环境（`.venv/`）
  一律不提交 Git（见仓库根 `.gitignore`）。
- 相对日期统一使用 referenceDate = 2026-10-20（周二，Asia/Shanghai）。
- AI 严禁编造日期：无原文证据的日期必须输出 `null`。

## 运行

```powershell
# 1. 虚拟环境（Python 3.10）
D:\SoftOfClass\python31010\python.exe -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt

# 2. 下载模型（断点续传 + 大小/SHA256 校验）
.venv\Scripts\python.exe runner/download.py

# 3. Smoke（12 条代表性用例）
.venv\Scripts\python.exe runner/run_llm.py --model qwen3-0.6b --smoke

# 4. 全量 56 条
.venv\Scripts\python.exe runner/run_llm.py --model qwen3-0.6b
.venv\Scripts\python.exe runner/run_llm.py --model qwen2.5-0.5b

# 5. 规则基线（直接引用正式工程 Dart 解析器源码，零复制）
cd runner/rules_harness
flutter pub get
flutter test

# 6. 评分
cd ../..
.venv\Scripts\python.exe runner/score.py
```

## 模型

| 模型 | 文件 | 大小 | 许可 |
|---|---|---|---|
| Qwen3-0.6B Q4_K_M | `unsloth/Qwen3-0.6B-GGUF:Qwen3-0.6B-Q4_K_M.gguf` | 396,705,472 B | Apache-2.0 |
| Qwen2.5-0.5B Q4_K_M | `Qwen/Qwen2.5-0.5B-Instruct-GGUF:qwen2.5-0.5b-instruct-q4_k_m.gguf` | 491,400,032 B | Apache-2.0 |
