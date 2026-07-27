from __future__ import annotations

import shutil
import subprocess
import tempfile
import threading
import time
from datetime import datetime
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
TEMPLATE_HOST_DIR = REPO_ROOT / "hosts" / "generated"
CRYPT_NAME = "cryptroot"
LOG_DIR = REPO_ROOT / ".installer-logs"
# Backup'ы намеренно лежат ВНЕ hosts/, иначе flake подхватывает их как хосты.
BACKUP_DIR = REPO_ROOT / ".installer-backups"

_LOG_FILE: Path | None = None
_SECRETS: list[str] = []


def register_secret(value: str | None) -> None:
    """Пометить значение как секрет: оно не попадёт ни в stdout, ни в лог."""
    if value:
        _SECRETS.append(value)


def redact(text: str) -> str:
    for secret in _SECRETS:
        if secret:
            text = text.replace(secret, "********")
    return text


def log_file() -> Path:
    """Лениво создать файл лога.

    Каталог создаётся только при первом реальном обращении, а не на импорте
    модуля: репозиторий может лежать в read-only каталоге (или на squashfs
    live-образа). В этом случае используется /tmp.
    """
    global _LOG_FILE
    if _LOG_FILE is not None:
        return _LOG_FILE

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    candidates = [LOG_DIR, Path(tempfile.gettempdir()) / "nixos-niri-installer"]
    for directory in candidates:
        try:
            directory.mkdir(parents=True, exist_ok=True)
            candidate = directory / f"install-{stamp}.log"
            candidate.touch()
        except OSError:
            continue
        _LOG_FILE = candidate
        return _LOG_FILE

    raise RuntimeError("Не удалось создать файл лога установки.")


def log_message(message: str) -> None:
    with log_file().open("a", encoding="utf-8") as handle:
        handle.write(redact(message).rstrip() + "\n")


def run(
    command: list[str],
    *,
    check: bool = True,
    stdin_data: str | None = None,
    stream: bool = False,
) -> subprocess.CompletedProcess:
    """Запустить команду.

    stdin_data — данные на stdin процесса (используется для передачи LUKS-пароля,
    чтобы он не оказался ни в argv, ни в `ps`, ни в логе).
    stream — не перехватывать вывод, показывать его пользователю в реальном
    времени (нужно для долгих команд вроде nixos-install).
    """
    pretty = redact(" ".join(command))
    print(f"\n$ {pretty}")
    with log_file().open("a", encoding="utf-8") as handle:
        handle.write(f"\n$ {pretty}\n")
        handle.flush()
        if stream:
            completed = subprocess.run(
                command,
                check=check,
                input=stdin_data,
                text=stdin_data is not None,
            )
        else:
            completed = subprocess.run(
                command,
                check=check,
                input=stdin_data,
                text=stdin_data is not None,
                stdout=handle,
                stderr=subprocess.STDOUT,
            )
        handle.flush()
    return completed


def run_quiet(command: list[str]) -> bool:
    """Запустить команду, игнорируя любые ошибки. Используется в cleanup."""
    try:
        return run(command, check=False).returncode == 0
    except Exception as error:  # noqa: BLE001 - cleanup не должен падать
        log_message(f"cleanup: {command} -> {error}")
        return False


def print_progress(step: int, total: int, title: str) -> None:
    width = 24
    filled = int((step / total) * width)
    bar = "█" * filled + "░" * (width - filled)
    percent = int((step / total) * 100)
    print(f"\n[{step}/{total}] {bar} {percent}% — {title}")


def run_with_spinner(command: list[str], title: str) -> None:
    stop = False

    def spinner() -> None:
        frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
        index = 0
        while not stop:
            print(f"\r{frames[index % len(frames)]} {title}...", end="", flush=True)
            index += 1
            time.sleep(0.1)
        print(f"\r✓ {title}...{' ' * 20}")

    thread = threading.Thread(target=spinner, daemon=True)
    thread.start()
    try:
        run(command)
    finally:
        stop = True
        thread.join()


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def blkid_value(device: str, key: str) -> str | None:
    result = subprocess.run(["blkid", "-s", key, "-o", "value", device], capture_output=True, text=True)
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def partition_suffix(disk: str, number: int) -> str:
    """Имя N-го раздела для диска.

    Общее ядерное правило: если имя устройства заканчивается цифрой, между ним
    и номером раздела ставится "p": nvme0n1p1, mmcblk0p1, loop0p1.
    Иначе номер клеится напрямую: sda1, vda1.

    Раньше проверялись только подстроки "nvme" и "mmcblk", поэтому для
    loop-устройств получалось несуществующее /dev/loop01.
    """
    return f"{disk}p{number}" if disk[-1:].isdigit() else f"{disk}{number}"
