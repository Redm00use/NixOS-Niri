from __future__ import annotations

import json
import shutil
import re
from datetime import datetime
from pathlib import Path

from .common import BACKUP_DIR, REPO_ROOT, TEMPLATE_HOST_DIR


def host_paths(host_name: str) -> tuple[Path, Path, Path]:
    target_host_dir = REPO_ROOT / "hosts" / host_name
    return target_host_dir, target_host_dir / "meta.nix", target_host_dir / "hardware-configuration.nix"


def ensure_host_files_for(host_name: str) -> tuple[Path, Path, Path]:
    target_host_dir, _, target_hardware = host_paths(host_name)
    target_default = target_host_dir / "default.nix"
    target_host_dir.mkdir(parents=True, exist_ok=True)
    if not target_default.exists():
        shutil.copy2(TEMPLATE_HOST_DIR / "default.nix", target_default)
    if not target_hardware.exists():
        shutil.copy2(TEMPLATE_HOST_DIR / "hardware-configuration.nix", target_hardware)
    return target_host_dir, target_default, target_hardware


def backup_host_dir(host_name: str) -> Path | None:
    """Скопировать hosts/<host> в .installer-backups/.

    Раньше backup складывался рядом, в hosts/<host>.backup-<timestamp>, и flake
    честно превращал каждую копию в отдельный nixosConfiguration.
    """
    target_host_dir, _, _ = host_paths(host_name)
    if not target_host_dir.exists():
        return None
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    backup_dir = BACKUP_DIR / f"{host_name}.backup-{timestamp}"
    shutil.copytree(target_host_dir, backup_dir)
    return backup_dir


def write_meta(
    user_name: str,
    host_name: str,
    gpu_type: str,
    role: str,
    time_zone: str,
    default_locale: str,
    separate_home: bool = False,
    home_size_gib: int = 0,
    swap_size_gib: int = 0,
    luks_enabled: bool = False,
    filesystem: str = "btrfs",
    luks_part_uuid: str | None = None,
    swap_uuid: str | None = None,
    host_dir: Path | None = None,
    preserve_storage: bool = False,
) -> None:
    actual_host_dir = host_dir or (REPO_ROOT / "hosts" / host_name)
    actual_host_dir.mkdir(parents=True, exist_ok=True)
    target_meta = actual_host_dir / "meta.nix"
    values = {
        "hostName": host_name, "userName": user_name, "gpuType": gpu_type,
        "role": role, "timeZone": time_zone, "defaultLocale": default_locale,
    }
    if not preserve_storage or not target_meta.exists():
        values.update({
            "separateHome": separate_home, "homeSizeGiB": home_size_gib,
            "swapSizeGiB": swap_size_gib, "luksEnabled": luks_enabled,
            "rootFs": filesystem, "luksPartUuid": luks_part_uuid, "swapUuid": swap_uuid,
        })
    body = "{\n" + "".join(f"  {key} = {nix_value(value)};\n" for key, value in values.items()) + "}\n"
    # Preserve custom attributes (system, initialPassword, etc.) and storage
    # settings when only the basic configuration is being regenerated.
    if target_meta.exists():
        body = "(\n" + target_meta.read_text(encoding="utf-8").rstrip() + "\n) // " + body
    target_meta.write_text(body, encoding="utf-8")


def nix_value(value) -> str:
    return json.dumps(value, ensure_ascii=False).replace("${", "\\${")



def export_answers(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def import_answers(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    validate_answers(data)
    return data


def validate_answers(data: dict) -> None:
    if not isinstance(data, dict):
        raise ValueError("JSON должен содержать объект с параметрами установки.")
    enums = {
        "mode": {"config", "live"}, "role": {"desktop", "server"},
        "gpu": {"amd", "nvidia", "intel", "vm"}, "fs": {"btrfs", "ext4"},
        "preset": {"custom", "desktop-amd", "desktop-nvidia", "desktop-intel", "vm", "server"},
    }
    strings = {"user", "host", "timezone", "locale", "disk"}
    integers = {"home_size_gib", "swap_size_gib"}
    booleans = {"luks", "separate_home"}
    for key, value in data.items():
        if key not in set(enums) | strings | integers | booleans:
            raise ValueError(f"Неизвестный параметр JSON: {key}")
        if key in enums and (not isinstance(value, str) or value not in enums[key]):
            raise ValueError(f"Недопустимое значение {key}: {value!r}")
        if key in strings and (not isinstance(value, str) or not value or any(ord(c) < 32 for c in value)):
            raise ValueError(f"{key}: требуется непустая строка без управляющих символов.")
        if key in integers and (type(value) is not int or value < 0):
            raise ValueError(f"{key}: требуется целое число >= 0.")
        if key in booleans and type(value) is not bool:
            raise ValueError(f"{key}: требуется true или false.")
    if "timezone" in data:
        from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
        try:
            ZoneInfo(data["timezone"])
        except (ValueError, ZoneInfoNotFoundError) as error:
            raise ValueError("Неизвестный часовой пояс: " + data["timezone"]) from error
    if "locale" in data and not re.fullmatch(r"[a-z]{2,3}_[A-Z]{2}\.UTF-8", data["locale"]):
        raise ValueError("Locale должен иметь вид ru_RU.UTF-8.")


def backup_file(path: Path) -> Path | None:
    """Сохранить копию файла в .installer-backups/, а не рядом с оригиналом."""
    if not path.exists():
        return None
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    backup_path = BACKUP_DIR / f"{path.parent.name}-{path.name}.backup-{timestamp}"
    shutil.copy2(path, backup_path)
    return backup_path
