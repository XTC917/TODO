"""Shared model registry + download utilities for the local-AI experiment."""
from __future__ import annotations

import hashlib
import os
import sys
from dataclasses import dataclass
from pathlib import Path

import requests
from tqdm import tqdm

ROOT = Path(__file__).resolve().parent.parent
MODELS_DIR = ROOT / "models"
OUT_DIR = ROOT / "out"
DATASETS_DIR = ROOT / "datasets"

TIMEOUT = 60
RETRIES = 4
CHUNK = 1024 * 1024


@dataclass(frozen=True)
class ModelSpec:
    key: str
    repo: str
    filename: str
    size: int
    revision: str
    license: str
    enable_thinking: bool

    @property
    def local_path(self) -> Path:
        return MODELS_DIR / self.filename


# Sizes were read from the HuggingFace API (bytes) in Step 1.
MODELS = {
    "qwen3-0.6b": ModelSpec(
        key="qwen3-0.6b",
        repo="unsloth/Qwen3-0.6B-GGUF",
        filename="Qwen3-0.6B-Q4_K_M.gguf",
        size=396_705_472,
        revision="50968a4468ef4233ed78cd7c3de230dd1d61a56b",
        license="Apache-2.0",
        enable_thinking=False,
    ),
    "qwen2.5-0.5b": ModelSpec(
        key="qwen2.5-0.5b",
        repo="Qwen/Qwen2.5-0.5B-Instruct-GGUF",
        filename="qwen2.5-0.5b-instruct-q4_k_m.gguf",
        size=491_400_032,
        revision="9217f5db79a29953eb74d5343926648285ec7e67",
        license="Apache-2.0",
        enable_thinking=False,
    ),
}


def _url(spec: ModelSpec) -> str:
    return f"https://huggingface.co/{spec.repo}/resolve/{spec.revision}/{spec.filename}"


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def download(spec: ModelSpec) -> Path:
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    target = spec.local_path

    if target.exists() and target.stat().st_size == spec.size:
        print(f"[ok] {spec.filename} already complete ({spec.size} bytes)")
        return target

    part = target.with_suffix(target.suffix + ".part")
    resume_at = part.stat().st_size if part.exists() else 0

    headers = {}
    if resume_at:
        headers["Range"] = f"bytes={resume_at}-"
        print(f"[resume] {spec.filename} from {resume_at} bytes")

    attempt = 0
    while attempt < RETRIES:
        attempt += 1
        try:
            with requests.get(
                _url(spec), headers=headers, stream=True, timeout=TIMEOUT
            ) as response:
                response.raise_for_status()
                total = spec.size
                mode = "ab" if headers else "wb"
                with part.open(mode) as handle, tqdm(
                    total=total,
                    initial=resume_at if headers else 0,
                    unit="B",
                    unit_scale=True,
                    desc=spec.filename,
                ) as bar:
                    for chunk in response.iter_content(chunk_size=CHUNK):
                        if not chunk:
                            continue
                        handle.write(chunk)
                        bar.update(len(chunk))
            break
        except Exception as exc:  # noqa: BLE001 - experiment script
            print(f"[retry {attempt}/{RETRIES}] {exc}")
            headers = {}
            resume_at = part.stat().st_size if part.exists() else 0
            if resume_at:
                headers["Range"] = f"bytes={resume_at}-"

    if part.stat().st_size != spec.size:
        raise RuntimeError(
            f"size mismatch for {spec.filename}: "
            f"{part.stat().st_size} != {spec.size}"
        )

    os.replace(part, target)
    print(f"[done] {spec.filename} sha256={_sha256(target)}")
    return target


def main() -> int:
    keys = sys.argv[1:] or list(MODELS)
    for key in keys:
        spec = MODELS[key]
        print(f"==> {key}: {spec.repo}/{spec.filename} ({spec.size} bytes, {spec.license})")
        download(spec)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
