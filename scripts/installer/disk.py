from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

from .common import CRYPT_NAME, REPO_ROOT, blkid_value, partition_suffix, run, shlex_quote


def prompt_disk() -> str:
    print("\nДоступные диски:")
    run(["lsblk", "-d", "-o", "NAME,SIZE,MODEL"], check=False)
    disk = input("Укажи диск для установки, например /dev/nvme0n1: ").strip()
    if not disk.startswith("/dev/"):
        print("Ошибка: укажи путь вида /dev/sdX или /dev/nvme0n1")
        sys.exit(1)
    return disk


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
    run(["nixos-generate-config", "--root", "/mnt"])


def copy_hardware_config(target_hardware: Path) -> None:
    shutil.copy2("/mnt/etc/nixos/hardware-configuration.nix", target_hardware)


def install_system(host_name: str) -> None:
    target_repo = Path("/mnt/etc/nixos/nixdots")
    if target_repo.exists():
        shutil.rmtree(target_repo)
    shutil.copytree(REPO_ROOT, target_repo)
    run(["nixos-install", "--flake", f"{target_repo}#{host_name}"])


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

