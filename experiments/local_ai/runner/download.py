"""Download approved GGUF models with resume + integrity checks."""
from __future__ import annotations

from common import MODELS, download


def main() -> int:
    for spec in MODELS.values():
        print(f"==> {spec.key}: {spec.repo}/{spec.filename}")
        print(f"    size={spec.size} bytes  license={spec.license}  rev={spec.revision}")
        download(spec)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
