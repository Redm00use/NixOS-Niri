from __future__ import annotations

import argparse
import traceback
from pathlib import Path

from .common import log_file, log_message, print_progress, register_secret
from .disk import (
    capture_layout_ids,
    cleanup_mounts,
    confirm_disk_name,
    copy_hardware_config,
    describe_plan,
    format_and_mount,
    generate_hardware_config,
    install_system,
    preflight_checks,
    prompt_disk,
    require_root,
)
from .meta import backup_file, backup_host_dir, ensure_host_files_for, export_answers, import_answers, write_meta
from .prompts import (
    GPU_VALUES,
    choose_filesystem,
    choose_gpu,
    choose_locale,
    choose_mode,
    choose_preset,
    choose_role,
    choose_timezone,
    choose_yes_no,
    print_header,
    prompt,
    prompt_int,
    prompt_passphrase,
    show_summary,
    validate_host_name,
    validate_user_name,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="NixOS/Niri installer and host generator")
    parser.add_argument("--mode", choices=["config", "live"])
    parser.add_argument("--user")
    parser.add_argument("--host")
    parser.add_argument("--role", choices=["desktop", "server"])
    parser.add_argument("--timezone")
    parser.add_argument("--locale")
    # 'vm' тоже валиден: modules/system/profiles/gpu/vm.nix существует,
    # а интерактивное меню его всегда предлагало.
    parser.add_argument("--gpu", choices=GPU_VALUES)
    parser.add_argument("--fs", choices=["btrfs", "ext4"])
    parser.add_argument("--disk")
    parser.add_argument("--separate-home", action="store_true", default=None)
    parser.add_argument("--home-size-gib", type=int)
    parser.add_argument("--swap-size-gib", type=int)
    parser.add_argument("--luks", action="store_true", default=None)
    parser.add_argument(
        "--luks-passphrase",
        help="Небезопасно: пароль виден в ps и истории shell. Лучше --luks-passphrase-file.",
    )
    parser.add_argument(
        "--luks-passphrase-file",
        help="Путь к файлу с LUKS-паролем (без завершающего перевода строки).",
    )
    parser.add_argument("--yes", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--export-json")
    parser.add_argument("--import-json")
    return parser.parse_args()


def pick(*values):
    """Вернуть первое значение, которое было явно задано.

    Старый код использовал `a or b or prompt()`, поэтому false и 0 из --import-json
    считались "не задано" и снова спрашивались у пользователя.
    """
    for value in values:
        if value is not None:
            return value
    return None


def read_passphrase_file(path: str) -> str:
    content = Path(path).read_text(encoding="utf-8")
    return content[:-1] if content.endswith("\n") else content


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

    imported = import_answers(Path(args.import_json)) if args.import_json else {}

    print_header("Базовая конфигурация", "Шаг 1/4")
    print_progress(1, 4, "Базовая конфигурация")
    mode = pick(args.mode, imported.get("mode"))
    if mode is None:
        mode = choose_mode()

    # Инструменты проверяем после выбора режима: config-режиму они не нужны.
    preflight_checks(mode)

    preset = pick(imported.get("preset"))
    if preset is None:
        preset = choose_preset() if args.mode is None and args.gpu is None and args.role is None else "custom"

    user_name = validate_user_name(pick(args.user, imported.get("user")) or prompt("Имя пользователя", "kotlin"))
    host_name = validate_host_name(pick(args.host, imported.get("host")) or prompt("Имя хоста / flake host", "niri"))

    role = pick(args.role, imported.get("role"))
    if role is None:
        role = "server" if preset == "server" else choose_role()

    time_zone = pick(args.timezone, imported.get("timezone"))
    if time_zone is None:
        time_zone = choose_timezone()

    default_locale = pick(args.locale, imported.get("locale"))
    if default_locale is None:
        default_locale = choose_locale()

    gpu_type = pick(args.gpu, imported.get("gpu"))
    if gpu_type is None:
        preset_gpu = {
            "desktop-amd": "amd",
            "desktop-nvidia": "nvidia",
            "desktop-intel": "intel",
            "vm": "vm",
        }.get(preset)
        gpu_type = preset_gpu if preset_gpu is not None else choose_gpu()

    backup_dir = backup_host_dir(host_name)
    target_host_dir, _, target_hardware = ensure_host_files_for(host_name)

    if mode == "config":
        if not args.yes:
            confirm(user_name, host_name, gpu_type, role, time_zone, default_locale)
        write_meta(user_name, host_name, gpu_type, role, time_zone, default_locale, host_dir=target_host_dir)
        print("\nГотово.")
        if backup_dir is not None:
            print(f"Создан backup: {backup_dir}")
        print(f"Обновлён файл: {target_host_dir / 'meta.nix'}")
        print(f"Дальше обнови {target_hardware} под этот ПК.")
        print(f"Применить: sudo nixos-rebuild switch --flake .#{host_name}")
        return 0

    require_root()
    print_header("Настройки диска", "Шаг 2/4")
    print_progress(2, 4, "Настройки диска")

    filesystem = pick(args.fs, imported.get("fs"))
    if filesystem is None:
        filesystem = "ext4" if preset == "vm" else choose_filesystem()

    disk = pick(args.disk, imported.get("disk"))
    if disk is None:
        disk = prompt_disk()

    separate_home = pick(args.separate_home, imported.get("separate_home"))
    if separate_home is None:
        separate_home = False if preset == "vm" else choose_yes_no("Отдельный раздел /home?", False)

    home_size_gib = pick(args.home_size_gib, imported.get("home_size_gib"))
    if home_size_gib is None:
        home_size_gib = prompt_int("Размер /home в GiB", 200) if separate_home else 0

    swap_size_gib = pick(args.swap_size_gib, imported.get("swap_size_gib"))
    if swap_size_gib is None:
        swap_size_gib = 4 if preset == "vm" else prompt_int("Размер swap в GiB (0 = без swap-раздела)", 8)

    luks_enabled = pick(args.luks, imported.get("luks"))
    if luks_enabled is None:
        luks_enabled = False if preset == "vm" else choose_yes_no("Включить LUKS для root?", False)

    if separate_home and home_size_gib <= 0:
        print("Ошибка: при отдельном /home размер должен быть больше 0 GiB.")
        print("Иначе parted создаст раздел нулевого размера и установка сломается.")
        return 1

    luks_passphrase = None
    if luks_enabled:
        if args.luks_passphrase_file:
            luks_passphrase = read_passphrase_file(args.luks_passphrase_file)
        elif args.luks_passphrase:
            print("Предупреждение: --luks-passphrase виден в ps и истории shell.")
            print("Рекомендуется --luks-passphrase-file.")
            luks_passphrase = args.luks_passphrase
        else:
            luks_passphrase = prompt_passphrase()
        if not luks_passphrase:
            print("Ошибка: пустой LUKS-пароль.")
            return 1
        register_secret(luks_passphrase)

    # Теперь известны ФС и LUKS — проверяем mkfs.*/cryptsetup до того, как трогать диск.
    preflight_checks(mode, filesystem, luks_enabled)

    if args.export_json:
        export_answers(
            Path(args.export_json),
            {
                "mode": mode,
                "preset": preset,
                "user": user_name,
                "host": host_name,
                "role": role,
                "timezone": time_zone,
                "locale": default_locale,
                "gpu": gpu_type,
                "fs": filesystem,
                "disk": disk,
                "separate_home": separate_home,
                "home_size_gib": home_size_gib,
                "swap_size_gib": swap_size_gib,
                "luks": luks_enabled,
            },
        )

    print_header("План установки", "Шаг 3/4")
    print_progress(3, 4, "План установки")
    for line in describe_plan(disk, filesystem, separate_home, home_size_gib, swap_size_gib, luks_enabled):
        print(f"- {line}")

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

    confirm_disk_name(disk, assume_yes=args.yes)

    if args.dry_run:
        print("\nDry-run завершён. Ничего не было изменено.")
        if backup_dir is not None:
            print(f"Backup host dir: {backup_dir}")
        print(f"Log file: {log_file()}")
        return 0

    print_header("Установка", "Шаг 4/4")
    print_progress(4, 4, "Установка")
    old_hardware_backup = None
    try:
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
        old_hardware_backup = backup_file(target_hardware)
        generate_hardware_config()
        copy_hardware_config(target_hardware)
        install_system(host_name)
    except Exception as error:  # noqa: BLE001 - показываем понятную ошибку, трейс в лог
        print("\nОшибка установки.")
        print("Стадия: Установка / финализация")
        print(f"Причина: {error}")
        log_message(traceback.format_exc())
        print(f"Лог: {log_file()}")
        cleanup_mounts(luks_enabled)
        return 1

    print("\nУстановка завершена.")
    show_summary(
        "Итог установки",
        [
            ("Host", host_name),
            ("User", user_name),
            ("Role", role),
            ("GPU", gpu_type),
            ("Disk", disk),
            ("Root FS", filesystem),
            ("LUKS", "yes" if luks_enabled else "no"),
            ("Swap GiB", str(swap_size_gib)),
            ("flake", f".#{host_name}"),
        ],
    )
    if backup_dir is not None:
        print(f"Backup host dir: {backup_dir}")
    if old_hardware_backup is not None:
        print(f"Hardware config backup: {old_hardware_backup}")
    print(f"Log file: {log_file()}")
    print("У root пароль не задан (--no-root-passwd).")
    print(f"Войди как {user_name} и сразу смени пароль: passwd")
    print("Можно перезагружаться в установленную систему.")
    print(f"Система доступна как flake target: .#{host_name}")
    return 0
