from __future__ import annotations

from pathlib import Path
from . import disk as storage
from .common import CRYPT_NAME, partition_suffix


def format_lvm_and_mount(disk: str, filesystem: str, separate_home: bool,
                         home_size_gib: int, swap_size_gib: int, luks_enabled: bool,
                         passphrase: str | None, resources: storage.InstallResources) -> None:
    storage.check_lvm_available()
    if luks_enabled and not passphrase:
        raise RuntimeError("LUKS включён, но пароль не задан.")
    run = storage.run
    Path("/mnt").mkdir(parents=True, exist_ok=True)
    efi, partition = partition_suffix(disk, 1), partition_suffix(disk, 2)
    run(["wipefs", "--all", "--force", disk])
    storage.settle_disk(disk)
    run(["parted", "-s", disk, "mklabel", "gpt"])
    run(["parted", "-s", disk, "mkpart", "ESP", "fat32", "1MiB", "513MiB"])
    run(["parted", "-s", disk, "set", "1", "esp", "on"])
    run(["parted", "-s", disk, "mkpart", "primary", "513MiB", "100%"])
    if not luks_enabled:
        run(["parted", "-s", disk, "set", "2", "lvm", "on"])
    storage.settle_disk(disk)
    storage.wait_for_device(efi)
    storage.wait_for_device(partition)
    run(["mkfs.fat", "-F", "32", efi])
    pv_device = partition
    if luks_enabled:
        run(["cryptsetup", "luksFormat", "--type", "luks2", "--batch-mode",
             "--key-file", "-", partition], stdin_data=passphrase)
        run(["cryptsetup", "open", "--key-file", "-", partition, CRYPT_NAME], stdin_data=passphrase)
        resources.crypt_open = True
        pv_device = f"/dev/mapper/{CRYPT_NAME}"
        storage.wait_for_device(pv_device)
    run(["pvcreate", "--force", "--yes", pv_device])
    run(["vgcreate", storage.LVM_VG_NAME, pv_device])
    resources.lvm_vg = storage.LVM_VG_NAME
    if swap_size_gib > 0:
        run(["lvcreate", "--size", f"{swap_size_gib}G", "--name", "swap", storage.LVM_VG_NAME])
    if separate_home:
        run(["lvcreate", "--size", f"{home_size_gib}G", "--name", "home", storage.LVM_VG_NAME])
    run(["lvcreate", "--extents", "100%FREE", "--name", "root", storage.LVM_VG_NAME])
    run(["udevadm", "settle"])
    root_device = f"/dev/{storage.LVM_VG_NAME}/root"
    storage.wait_for_device(root_device)
    if swap_size_gib > 0:
        swap_device = f"/dev/{storage.LVM_VG_NAME}/swap"
        storage.wait_for_device(swap_device)
        run(["mkswap", swap_device])
        run(["swapon", swap_device])
        resources.swap_device = swap_device
    home_device = f"/dev/{storage.LVM_VG_NAME}/home" if separate_home else None
    if home_device:
        storage.wait_for_device(home_device)
        run(["mkfs.btrfs", "-f", home_device] if filesystem == "btrfs" else ["mkfs.ext4", "-F", home_device])
    storage.mount_target_filesystems(filesystem, efi, root_device, home_device, resources)
