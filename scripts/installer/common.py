from __future__ import annotations

import subprocess
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
TEMPLATE_HOST_DIR = REPO_ROOT / "hosts" / "generated"
CRYPT_NAME = "cryptroot"


def run(command: list[str], *, check: bool = True) -> None:
    print(f"\n$ {' '.join(command)}")
    subprocess.run(command, check=check)


def blkid_value(device: str, key: str) -> str | None:
    result = subprocess.run(["blkid", "-s", key, "-o", "value", device], capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def partition_suffix(disk: str, number: int) -> str:
    return f"{disk}p{number}" if "nvme" in disk or "mmcblk" in disk else f"{disk}{number}"


def shlex_quote(value: str) -> str:
    return "'" + value.replace("'", "'\"'\"'") + "'"

