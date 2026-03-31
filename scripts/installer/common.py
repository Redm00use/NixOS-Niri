from __future__ import annotations

import subprocess
from pathlib import Path
import shutil
from datetime import datetime


REPO_ROOT = Path(__file__).resolve().parents[2]
TEMPLATE_HOST_DIR = REPO_ROOT / "hosts" / "generated"
CRYPT_NAME = "cryptroot"
LOG_DIR = REPO_ROOT / ".installer-logs"
LOG_DIR.mkdir(exist_ok=True)
LOG_FILE = LOG_DIR / f"install-{datetime.now().strftime('%Y%m%d-%H%M%S')}.log"


def run(command: list[str], *, check: bool = True) -> None:
    print(f"\n$ {' '.join(command)}")
    with LOG_FILE.open("a", encoding="utf-8") as log_file:
        log_file.write(f"\n$ {' '.join(command)}\n")
        subprocess.run(command, check=check, stdout=log_file, stderr=log_file)


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def blkid_value(device: str, key: str) -> str | None:
    result = subprocess.run(["blkid", "-s", key, "-o", "value", device], capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def partition_suffix(disk: str, number: int) -> str:
    return f"{disk}p{number}" if "nvme" in disk or "mmcblk" in disk else f"{disk}{number}"


def shlex_quote(value: str) -> str:
    return "'" + value.replace("'", "'\"'\"'") + "'"
