from __future__ import annotations

import argparse

from .disk import capture_layout_ids, copy_hardware_config, format_and_mount, generate_hardware_config, install_system, prompt_disk, require_root
from .meta import ensure_host_files_for, write_meta
from .prompts import choose_filesystem, choose_gpu, choose_mode, choose_role, choose_yes_no, print_header, prompt, prompt_int, prompt_passphrase, show_summary, validate_name


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="NixOS/Niri installer and host generator")
    parser.add_argument("--mode", choices=["config", "live"])
    parser.add_argument("--user")
    parser.add_argument("--host")
    parser.add_argument("--role", choices=["desktop", "server"])
    parser.add_argument("--timezone")
    parser.add_argument("--locale")
    parser.add_argument("--gpu", choices=["amd", "nvidia", "intel"])
    parser.add_argument("--fs", choices=["btrfs", "ext4"])
    parser.add_argument("--disk")
    parser.add_argument("--separate-home", action="store_true")
    parser.add_argument("--home-size-gib", type=int)
    parser.add_argument("--swap-size-gib", type=int)
    parser.add_argument("--luks", action="store_true")
    parser.add_argument("--luks-passphrase")
    parser.add_argument("--yes", action="store_true")
    return parser.parse_args()


def confirm(user_name: str, host_name: str, gpu_type: str, role: str, time_zone: str, default_locale: str) -> None:
    show_summary(
        "Подтверждение конфигурации",
        [
            ("Пользователь", user_name),
            ("Хост", host_name),
            ("Видеокарта", gpu_type),
            ("Роль", role),
            ("Timezone", time_zone),
            ("Locale", default_locale),
        ],
    )
    answer = input("Подтвердить? [y/N]: ").strip().lower()
    if answer != "y":
        raise SystemExit(1)


def confirm_live(
    user_name: str,
    host_name: str,
    gpu_type: str,
    role: str,
    time_zone: str,
    default_locale: str,
    filesystem: str,
    disk: str,
    separate_home: bool,
    home_size_gib: int,
    swap_size_gib: int,
    luks_enabled: bool,
) -> None:
    rows = [
        ("Пользователь", user_name),
        ("Хост", host_name),
        ("Видеокарта", gpu_type),
        ("Роль", role),
        ("Timezone", time_zone),
        ("Locale", default_locale),
        ("ФС root", filesystem),
        ("Диск", disk),
        ("Отдельный home", "yes" if separate_home else "no"),
        ("Swap GiB", str(swap_size_gib)),
        ("LUKS", "yes" if luks_enabled else "no"),
    ]
    if separate_home:
        rows.insert(9, ("Home GiB", str(home_size_gib)))
    show_summary("Подтверждение live-установки", rows)
    print("\nВНИМАНИЕ: диск будет ПОЛНОСТЬЮ стёрт")
    answer = input("Напиши ERASE для подтверждения: ").strip()
    if answer != "ERASE":
        raise SystemExit(1)


def main() -> int:
    print_header("NixOS / Niri Installer")
    args = parse_args()

    mode = args.mode or choose_mode()
    user_name = validate_name(args.user or prompt("Имя пользователя", "kotlin"), "Имя пользователя")
    host_name = validate_name(args.host or prompt("Имя хоста / flake host", "niri"), "Имя хоста")
    role = args.role or choose_role()
    time_zone = args.timezone or prompt("Часовой пояс", "Europe/Kyiv")
    default_locale = args.locale or prompt("Locale", "ru_RU.UTF-8")
    gpu_type = args.gpu or choose_gpu()

    target_host_dir, _, target_hardware = ensure_host_files_for(host_name)

    if mode == "config":
        if not args.yes:
            confirm(user_name, host_name, gpu_type, role, time_zone, default_locale)
        write_meta(user_name, host_name, gpu_type, role, time_zone, default_locale, host_dir=target_host_dir)
        print("\nГотово.")
        print(f"Обновлён файл: {target_host_dir / 'meta.nix'}")
        print(f"Дальше обнови {target_hardware} под этот ПК.")
        print(f"Применить: sudo nixos-rebuild switch --flake .#{host_name}")
        return 0

    require_root()
    filesystem = args.fs or choose_filesystem()
    disk = args.disk or prompt_disk()
    separate_home = args.separate_home or choose_yes_no("Отдельный раздел /home?", False)
    home_size_gib = args.home_size_gib if args.home_size_gib is not None else (prompt_int("Размер /home в GiB", 200) if separate_home else 0)
    swap_size_gib = args.swap_size_gib if args.swap_size_gib is not None else prompt_int("Размер swap в GiB (0 = без swap-раздела)", 8)
    luks_enabled = args.luks or choose_yes_no("Включить LUKS для root?", False)
    luks_passphrase = args.luks_passphrase or (prompt_passphrase() if luks_enabled else None)

    if not args.yes:
        confirm_live(
            user_name,
            host_name,
            gpu_type,
            role,
            time_zone,
            default_locale,
            filesystem,
            disk,
            separate_home,
            home_size_gib,
            swap_size_gib,
            luks_enabled,
        )

    format_and_mount(disk, filesystem, separate_home, home_size_gib, swap_size_gib, luks_enabled, luks_passphrase)
    luks_part_uuid, swap_uuid = capture_layout_ids(disk, separate_home, swap_size_gib, luks_enabled)
    write_meta(
        user_name,
        host_name,
        gpu_type,
        role,
        time_zone,
        default_locale,
        separate_home,
        home_size_gib,
        swap_size_gib,
        luks_enabled,
        filesystem,
        luks_part_uuid,
        swap_uuid,
        target_host_dir,
    )
    generate_hardware_config()
    copy_hardware_config(target_hardware)
    install_system(host_name)
    print("\nУстановка завершена.")
    print("Можно перезагружаться в установленную систему.")
    print(f"Система доступна как flake target: .#{host_name}")
    return 0
