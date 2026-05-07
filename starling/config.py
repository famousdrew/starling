from __future__ import annotations

import json
import os
from pathlib import Path

_PATH = Path(os.environ.get("APPDATA", Path.home())) / "Starling" / "config.json"


def _load() -> dict:
    try:
        return json.loads(_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}


def get(key: str, default=None):
    return _load().get(key, default)


def set(key: str, value) -> None:
    data = _load()
    data[key] = value
    _PATH.parent.mkdir(parents=True, exist_ok=True)
    _PATH.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
