from __future__ import annotations

import os
import json
import shutil
import sys
import curses
from pathlib import Path

from .common import CRYPT_NAME, REPO_ROOT, blkid_value, partition_suffix, run, run_with_spinner, shlex_quote


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


def subprocess_output(command: list[str]) -> str:
    import subprocess
    completed = subprocess.run(command, capture_output=True, text=True, check=True)
    return completed.stdout


def prompt_disk() -> str:
    disks = list_disks()
    if not disks:
        print("Ошибка: не найдено подходящих дисков.")
        sys.exit(1)

    try:
        return prompt_disk_curses(disks)
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


def confirm_disk_name(disk: str) -> None:
    print("\nТекущая разметка дисков:")
    run(["lsblk", "-o", "NAME,SIZE,FSTYPE,TYPE,MOUNTPOINTS"])
    answer = input("Подтвердить выбор диска? [y/N]: ").strip().lower()
    if answer != "y":
        print("Отменено.")
        sys.exit(1)


def preflight_checks() -> None:
    required = [
        "lsblk",
        "parted",
        "mkfs.fat",
        "mount",
        "umount",
        "nixos-generate-config",
        "nixos-install",
        "blkid",
    ]
    missing = [cmd for cmd in required if shutil.which(cmd) is None]
    if missing:
        print(f"Ошибка: отсутствуют команды: {', '.join(missing)}")
        sys.exit(1)


def require_root() -> None:
    if os.geteuid() != 0:
        print("Ошибка: для live-установки запусти скрипт от root.")
        sys.exit(1)


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
        run(["bash", "-lc", f"printf '%s' {shlex_quote(luks_passphrase)} | cryptsetup luksFormat --batch-mode {root_partition} -"])
        run(["bash", "-lc", f"printf '%s' {shlex_quote(luks_passphrase)} | cryptsetup open {root_partition} {CRYPT_NAME} -"])
        root_device = f"/dev/mapper/{CRYPT_NAME}"

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
            ".git",
            "result",
            ".installer-logs",
            "__pycache__",
            "*.pyc",
            ".direnv",
        ),
        symlinks=False,
    )
    print("Сейчас начнётся сборка и установка системы. Это может занять несколько минут.")
    run_with_spinner(["nixos-install", "--flake", f"{target_repo}#{host_name}"], "Установка NixOS")


def cleanup_mounts() -> None:
    for mountpoint in ["/mnt/home", "/mnt/boot", "/mnt"]:
        try:
            run(["umount", mountpoint], check=False)
        except Exception:
            pass
    run(["swapoff", "-a"], check=False)


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
