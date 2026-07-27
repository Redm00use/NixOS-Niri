from __future__ import annotations

import curses
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

from .common import (
    CRYPT_NAME,
    REPO_ROOT,
    blkid_value,
    partition_suffix,
    run,
    run_quiet,
    run_with_spinner,
)


# Базовые утилиты, без которых live-установка в принципе не сработает.
BASE_REQUIRED_COMMANDS = [
    "lsblk",
    "parted",
    "partprobe",
    "udevadm",
    "wipefs",
    "blkid",
    "mkfs.fat",
    "mount",
    "umount",
    "mkswap",
    "swapon",
    "swapoff",
]
LIVE_REQUIRED_COMMANDS = ["nixos-generate-config", "nixos-install"]
FS_REQUIRED_COMMANDS = {
    "btrfs": ["mkfs.btrfs", "btrfs"],
    "ext4": ["mkfs.ext4"],
}


def subprocess_output(command: list[str]) -> str:
    completed = subprocess.run(command, capture_output=True, text=True, check=True)
    return completed.stdout


def list_disks() -> list[dict]:
    result = subprocess_output([
        "lsblk",
        "-J",
        "-d",
        "-e",
        "7,11",
        "-o",
        "NAME,SIZE,MODEL,TRAN,TYPE",
    ])
    payload = json.loads(result)
    return [device for device in payload.get("blockdevices", []) if device.get("type") == "disk"]


def prompt_disk() -> str:
    disks = list_disks()
    if not disks:
        print("Ошибка: не найдено подходящих дисков.")
        sys.exit(1)

    if not sys.stdin.isatty():
        print("Ошибка: диск не задан, а stdin не является терминалом.")
        print("Укажи диск явно: --disk /dev/nvme0n1")
        sys.exit(1)

    try:
        return prompt_disk_curses(disks)
    except SystemExit:
        raise
    except Exception:
        pass

    print("\nДоступные диски:")
    for index, device in enumerate(disks, start=1):
        name = device.get("name", "?")
        size = device.get("size", "?")
        model = device.get("model") or "unknown"
        transport = device.get("tran") or "-"
        print(f"{index}) /dev/{name}  |  {size}  |  {transport}  |  {model}")
    while True:
        answer = input("Номер диска [1]: ").strip() or "1"
        if answer.isdigit() and 1 <= int(answer) <= len(disks):
            return f"/dev/{disks[int(answer) - 1]['name']}"
        print("Неверный выбор, попробуй снова.")


def prompt_disk_curses(disks: list[dict]) -> str:
    def _selector(stdscr):
        curses.curs_set(0)
        stdscr.keypad(True)
        selected = 0

        while True:
            stdscr.clear()
            stdscr.addstr(0, 0, "Выбор диска")
            stdscr.addstr(1, 0, "Стрелки ↑/↓ — выбрать, Enter — подтвердить, q — выйти")
            stdscr.addstr(2, 0, "-" * 72)

            for index, device in enumerate(disks):
                name = f"/dev/{device.get('name', '?')}"
                size = device.get("size", "?")
                model = device.get("model") or "unknown"
                transport = device.get("tran") or "-"
                prefix = ">" if index == selected else " "
                line = f"{prefix} {name:<14} | {size:<8} | {transport:<6} | {model}"
                if index == selected:
                    stdscr.attron(curses.A_REVERSE)
                    stdscr.addstr(4 + index, 0, line[: max(1, curses.COLS - 1)])
                    stdscr.attroff(curses.A_REVERSE)
                else:
                    stdscr.addstr(4 + index, 0, line[: max(1, curses.COLS - 1)])

            key = stdscr.getch()
            if key in (curses.KEY_UP, ord("k")):
                selected = (selected - 1) % len(disks)
            elif key in (curses.KEY_DOWN, ord("j")):
                selected = (selected + 1) % len(disks)
            elif key in (10, 13, curses.KEY_ENTER):
                return f"/dev/{disks[selected]['name']}"
            elif key in (ord("q"), 27):
                raise SystemExit(1)

    return curses.wrapper(_selector)


def confirm_disk_name(disk: str, assume_yes: bool = False) -> None:
    print("\nТекущая разметка дисков:")
    # stream=True: раньше вывод lsblk уходил в лог, и "подтверди выбор" было вслепую.
    run(["lsblk", "-o", "NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS"], check=False, stream=True)
    if assume_yes:
        print(f"--yes: подтверждение диска {disk} пропущено.")
        return
    if not sys.stdin.isatty():
        print("Ошибка: нужно подтверждение диска, но stdin не терминал. Используй --yes.")
        sys.exit(1)
    answer = input(f"Подтвердить выбор диска {disk}? [y/N]: ").strip().lower()
    if answer != "y":
        print("Отменено.")
        sys.exit(1)


def preflight_checks(mode: str, filesystem: str | None = None, luks_enabled: bool = False) -> None:
    """Проверить только те утилиты, которые реально нужны.

    Режим config не требует ни nixos-install, ни parted — раньше генерация конфига
    на обычной машине падала ещё до первого вопроса.
    """
    if mode != "live":
        return

    required = list(BASE_REQUIRED_COMMANDS) + LIVE_REQUIRED_COMMANDS
    if filesystem:
        required += FS_REQUIRED_COMMANDS.get(filesystem, [])
    if luks_enabled:
        required.append("cryptsetup")

    missing = [command for command in dict.fromkeys(required) if shutil.which(command) is None]
    if missing:
        print(f"Ошибка: отсутствуют команды: {', '.join(missing)}")
        sys.exit(1)


def require_root() -> None:
    if os.geteuid() != 0:
        print("Ошибка: для live-установки запусти скрипт от root.")
        sys.exit(1)


def settle_disk(disk: str) -> None:
    """Заставить ядро и udev увидеть новую таблицу разделов."""
    run(["partprobe", disk], check=False)
    run(["udevadm", "settle"], check=False)


def wait_for_device(path: str, timeout: float = 20.0) -> None:
    """Дождаться появления устройства в /dev.

    Без этого mkfs.* иногда стартовал раньше, чем udev создавал node раздела.
    """
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if Path(path).exists():
            return
        time.sleep(0.3)
    raise RuntimeError(f"Устройство {path} не появилось за {timeout:.0f} с.")


def format_and_mount(
    disk: str,
    filesystem: str,
    separate_home: bool,
    home_size_gib: int,
    swap_size_gib: int,
    luks_enabled: bool,
    luks_passphrase: str | None,
) -> None:
    efi = partition_suffix(disk, 1)
    current_partition = 2
    swap_partition = partition_suffix(disk, current_partition) if swap_size_gib > 0 else None
    if swap_partition is not None:
        current_partition += 1
    home_partition = partition_suffix(disk, current_partition) if separate_home else None
    if home_partition is not None:
        current_partition += 1
    root_partition = partition_suffix(disk, current_partition)

    if luks_enabled and not luks_passphrase:
        raise RuntimeError("LUKS включён, но пароль не задан.")

    # Стираем старые подписи ФС/RAID/LUKS, иначе blkid и initrd могут найти призраки.
    run(["wipefs", "--all", "--force", disk])
    settle_disk(disk)

    run(["parted", "-s", disk, "mklabel", "gpt"])
    run(["parted", "-s", disk, "mkpart", "ESP", "fat32", "1MiB", "513MiB"])
    run(["parted", "-s", disk, "set", "1", "esp", "on"])

    cursor = 513
    if swap_partition is not None:
        next_cursor = cursor + (swap_size_gib * 1024)
        run(["parted", "-s", disk, "mkpart", "primary", "linux-swap", f"{cursor}MiB", f"{next_cursor}MiB"])
        cursor = next_cursor

    if home_partition is not None:
        next_cursor = cursor + (home_size_gib * 1024)
        run(["parted", "-s", disk, "mkpart", "primary", filesystem, f"{cursor}MiB", f"{next_cursor}MiB"])
        cursor = next_cursor

    root_fs_for_parted = "ext4" if luks_enabled else filesystem
    run(["parted", "-s", disk, "mkpart", "primary", root_fs_for_parted, f"{cursor}MiB", "100%"])

    settle_disk(disk)
    for partition in [efi, swap_partition, home_partition, root_partition]:
        if partition is not None:
            wait_for_device(partition)

    run(["mkfs.fat", "-F", "32", efi])
    if swap_partition is not None:
        run(["mkswap", swap_partition])
        run(["swapon", swap_partition])

    if home_partition is not None:
        if filesystem == "btrfs":
            run(["mkfs.btrfs", "-f", home_partition])
        else:
            run(["mkfs.ext4", "-F", home_partition])

    root_device = root_partition
    if luks_enabled:
        assert luks_passphrase is not None
        # Пароль уходит только в stdin процесса: не виден в argv, ps и логе.
        run(
            [
                "cryptsetup",
                "luksFormat",
                "--type",
                "luks2",
                "--batch-mode",
                "--key-file",
                "-",
                root_partition,
            ],
            stdin_data=luks_passphrase,
        )
        run(
            ["cryptsetup", "open", "--key-file", "-", root_partition, CRYPT_NAME],
            stdin_data=luks_passphrase,
        )
        root_device = f"/dev/mapper/{CRYPT_NAME}"
        wait_for_device(root_device)

    if filesystem == "btrfs":
        run(["mkfs.btrfs", "-f", root_device])
        run(["mount", root_device, "/mnt"])
        run(["btrfs", "subvolume", "create", "/mnt/@"])
        if home_partition is None:
            run(["btrfs", "subvolume", "create", "/mnt/@home"])
        run(["umount", "/mnt"])
        run(["mount", "-o", "subvol=@", root_device, "/mnt"])
    else:
        run(["mkfs.ext4", "-F", root_device])
        run(["mount", root_device, "/mnt"])

    run(["mkdir", "-p", "/mnt/boot"])
    run(["mount", efi, "/mnt/boot"])

    if home_partition is not None:
        run(["mkdir", "-p", "/mnt/home"])
        run(["mount", home_partition, "/mnt/home"])
    elif filesystem == "btrfs":
        run(["mkdir", "-p", "/mnt/home"])
        run(["mount", "-o", "subvol=@home", root_device, "/mnt/home"])


def generate_hardware_config() -> None:
    run_with_spinner(["nixos-generate-config", "--root", "/mnt"], "Генерация hardware-configuration.nix")


def copy_hardware_config(target_hardware: Path) -> None:
    shutil.copy2("/mnt/etc/nixos/hardware-configuration.nix", target_hardware)


def install_system(host_name: str) -> None:
    target_repo = Path("/mnt/etc/nixos/nixdots")
    if target_repo.exists():
        shutil.rmtree(target_repo)
    shutil.copytree(
        REPO_ROOT,
        target_repo,
        ignore=shutil.ignore_patterns(
            "result",
            ".installer-logs",
            ".installer-backups",
            "__pycache__",
            "*.pyc",
            ".direnv",
        ),
        symlinks=False,
    )
    print("Сейчас начнётся сборка и установка системы. Это может занять от 20 до 40 минут.")
    print("Вывод nixos-install показывается ниже целиком.")
    # --no-root-passwd: иначе nixos-install в конце ждёт интерактивный ввод пароля root
    # и весь non-interactive режим зависает. Пользователь создаётся конфигом.
    run(["nixos-install", "--flake", f"{target_repo}#{host_name}", "--no-root-passwd"], stream=True)


def cleanup_mounts(luks_enabled: bool = False) -> None:
    """Откатить монтирования и закрыть LUKS-маппинг.

    Без cryptsetup close повторный запуск инсталлера падал на "device is busy".
    """
    run_quiet(["umount", "-R", "/mnt"])
    run_quiet(["swapoff", "-a"])
    if luks_enabled or Path(f"/dev/mapper/{CRYPT_NAME}").exists():
        run_quiet(["cryptsetup", "close", CRYPT_NAME])


def describe_plan(
    disk: str,
    filesystem: str,
    separate_home: bool,
    home_size_gib: int,
    swap_size_gib: int,
    luks_enabled: bool,
) -> list[str]:
    lines = [
        f"Disk: {disk}",
        f"Root FS: {filesystem}",
        f"Separate /home: {'yes' if separate_home else 'no'}",
        f"Swap: {swap_size_gib} GiB",
        f"LUKS: {'yes' if luks_enabled else 'no'}",
    ]
    if separate_home:
        lines.append(f"Home size: {home_size_gib} GiB")
    if luks_enabled and swap_size_gib > 0:
        lines.append("Внимание: swap-раздел не шифруется, resume будет отключён")
    return lines


def capture_layout_ids(disk: str, separate_home: bool, swap_size_gib: int, luks_enabled: bool) -> tuple[str | None, str | None]:
    current_partition = 2
    swap_partition = partition_suffix(disk, current_partition) if swap_size_gib > 0 else None
    if swap_partition is not None:
        current_partition += 1
    if separate_home:
        current_partition += 1
    root_partition = partition_suffix(disk, current_partition)
    luks_part_uuid = blkid_value(root_partition, "PARTUUID") if luks_enabled else None
    swap_uuid = blkid_value(swap_partition, "UUID") if swap_partition is not None else None
    return luks_part_uuid, swap_uuid
