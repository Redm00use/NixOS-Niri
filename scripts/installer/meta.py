from __future__ import annotations

import json
import shutil
from pathlib import Path

from .common import REPO_ROOT, TEMPLATE_HOST_DIR


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
) -> None:
    actual_host_dir = host_dir or (REPO_ROOT / "hosts" / host_name)
    actual_host_dir.mkdir(parents=True, exist_ok=True)
    target_meta = actual_host_dir / "meta.nix"
    target_meta.write_text(
        "\n".join(
            [
                "{",
                f'  hostName = "{host_name}";',
                f'  userName = "{user_name}";',
                f'  gpuType = "{gpu_type}";',
                f'  role = "{role}";',
                f'  timeZone = "{time_zone}";',
                f'  defaultLocale = "{default_locale}";',
                f"  separateHome = {str(separate_home).lower()};",
                f"  homeSizeGiB = {home_size_gib};",
                f"  swapSizeGiB = {swap_size_gib};",
                f"  luksEnabled = {str(luks_enabled).lower()};",
                f'  rootFs = "{filesystem}";',
                f'  luksPartUuid = {json.dumps(luks_part_uuid)};',
                f'  swapUuid = {json.dumps(swap_uuid)};',
                "}",
                "",
            ]
        ),
        encoding="utf-8",
    )

