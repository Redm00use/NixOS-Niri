from __future__ import annotations

import argparse
import traceback
from pathlib import Path

from . import common
from .common import log_file, log_message, print_progress, register_secret, redact
from .disk import (
    InstallResources, capture_layout_ids, cleanup_mounts, confirm_disk_name,
    copy_hardware_config, describe_plan, format_and_mount, generate_hardware_config,
    install_system, preflight_checks, prompt_disk, require_root, validate_disk,
)
from .meta import (
    backup_host_dir, ensure_host_files_for, export_answers, import_answers,
    validate_answers, write_meta,
)
from .prompts import (
    GPU_VALUES, ask, choose_filesystem, choose_gpu, choose_locale, choose_mode,
    choose_preset, choose_role, choose_timezone, choose_yes_no, print_header,
    prompt, prompt_int, prompt_passphrase, show_summary, validate_host_name,
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
    parser.add_argument("--gpu", choices=GPU_VALUES)
    parser.add_argument("--fs", choices=["btrfs", "ext4"])
    parser.add_argument("--disk")
    parser.add_argument("--separate-home", action=argparse.BooleanOptionalAction, default=None)
    parser.add_argument("--home-size-gib", type=int)
    parser.add_argument("--swap-size-gib", type=int)
    parser.add_argument("--luks", action=argparse.BooleanOptionalAction, default=None)
    secret = parser.add_mutually_exclusive_group()
    secret.add_argument("--luks-passphrase", help="Пароль виден в ps; лучше --luks-passphrase-file.")
    secret.add_argument("--luks-passphrase-file", help="Файл пароля; один завершающий перевод строки удаляется.")
    parser.add_argument("--yes", action="store_true")
    parser.add_argument("--dry-run", action="store_true", help="Только план: без записи файлов и дисковых команд.")
    parser.add_argument("--export-json")
    parser.add_argument("--import-json")
    return parser.parse_args()


def pick(*values):
    return next((value for value in values if value is not None), None)


def read_passphrase_file(path: str) -> str:
    content = Path(path).read_text(encoding="utf-8")
    return content[:-1] if content.endswith("\n") else content


def collect_answers(args: argparse.Namespace) -> dict:
    data = import_answers(Path(args.import_json)) if args.import_json else {}
    for key in ("mode", "user", "host", "role", "timezone", "locale", "gpu", "fs",
                "disk", "separate_home", "home_size_gib", "swap_size_gib", "luks"):
        value = getattr(args, key)
        if value is not None:
            data[key] = value
    validate_answers(data)

    def resolve(key, chooser, default=None):
        if key not in data:
            if args.yes:
                if default is None:
                    raise ValueError(f"Для --yes требуется --{key.replace('_', '-')} или значение в JSON.")
                data[key] = default
            else:
                data[key] = chooser()
        return data[key]

    mode = resolve("mode", choose_mode)
    preset = resolve("preset", choose_preset, "custom") if not (args.mode or args.gpu or args.role) else data.setdefault("preset", "custom")
    validate_user_name(resolve("user", lambda: prompt("Имя пользователя", "kotlin")))
    validate_host_name(resolve("host", lambda: prompt("Имя хоста / flake host", "niri")))
    resolve("role", lambda: "server" if preset == "server" else choose_role(), "server" if preset == "server" else "desktop")
    resolve("timezone", choose_timezone, "Europe/Kyiv")
    resolve("locale", choose_locale, "ru_RU.UTF-8")
    preset_gpu = {"desktop-amd": "amd", "desktop-nvidia": "nvidia", "desktop-intel": "intel", "vm": "vm"}.get(preset)
    resolve("gpu", lambda: preset_gpu or choose_gpu(), preset_gpu)
    if mode == "live":
        resolve("fs", lambda: "ext4" if preset == "vm" else choose_filesystem(), "ext4" if preset == "vm" else "btrfs")
        resolve("disk", prompt_disk)
        resolve("separate_home", lambda: False if preset == "vm" else choose_yes_no("Отдельный раздел /home?", False), False)
        resolve("home_size_gib", lambda: prompt_int("Размер /home в GiB", 200) if data["separate_home"] else 0, 200 if data["separate_home"] else 0)
        resolve("swap_size_gib", lambda: 4 if preset == "vm" else prompt_int("Размер swap в GiB (0 = без swap)", 8), 4 if preset == "vm" else 8)
        resolve("luks", lambda: False if preset == "vm" else choose_yes_no("Включить LUKS для root?", False), False)
        if data["separate_home"] and data["home_size_gib"] <= 0:
            raise ValueError("Для отдельного /home требуется размер больше 0 GiB.")
        if not data["separate_home"] and data["home_size_gib"] != 0:
            raise ValueError("--home-size-gib требует --separate-home.")
    validate_answers(data)
    return data


def execute() -> int:
    args = parse_args()
    # Register argv secrets before any operation that can produce diagnostics.
    register_secret(args.luks_passphrase)
    print_header("NixOS / Niri Installer")
    data = collect_answers(args)
    mode, host = data["mode"], data["host"]
    show_summary("Конфигурация", [(key, str(value)) for key, value in data.items()])
    if mode == "live":
        for line in describe_plan(data["disk"], data["fs"], data["separate_home"],
                                  data["home_size_gib"], data["swap_size_gib"], data["luks"]):
            print(f"- {line}")
    if args.dry_run:
        print("\nDry-run завершён: файлы и диски не изменены; доступность диска и сборка не проверялись.")
        return 0

    passphrase = None
    if mode == "live":
        require_root()
        preflight_checks(mode, data["fs"], data["luks"])
        data["disk"] = validate_disk(data["disk"], data["home_size_gib"], data["swap_size_gib"], data["luks"])
        if data["luks"]:
            if args.luks_passphrase_file:
                passphrase = read_passphrase_file(args.luks_passphrase_file)
            elif args.luks_passphrase is not None:
                passphrase = args.luks_passphrase
            elif args.yes:
                raise ValueError("Для LUKS с --yes требуется --luks-passphrase-file.")
            else:
                passphrase = prompt_passphrase()
            if not passphrase:
                raise ValueError("Пустой пароль LUKS недопустим.")
            register_secret(passphrase)
        if not args.yes and ask("Диск будет полностью стёрт. Напиши ERASE: ").strip() != "ERASE":
            print("Отменено.")
            return 1
        confirm_disk_name(data["disk"], assume_yes=args.yes)
    elif not args.yes and ask("Подтвердить конфигурацию? [y/N]: ").strip().lower() != "y":
        print("Отменено.")
        return 1

    if args.export_json:
        export_answers(Path(args.export_json), data)
    backup = backup_host_dir(host)
    host_dir, _, hardware = ensure_host_files_for(host)
    basic = (data["user"], host, data["gpu"], data["role"], data["timezone"], data["locale"])
    if mode == "config":
        write_meta(*basic, host_dir=host_dir, preserve_storage=True)
        print(f"\nОбновлён {host_dir / 'meta.nix'}")
        print(f"Перед сборкой заполни {hardware} данными этого ПК (nixos-generate-config).")
        print(f"Применить из каталога проекта: sudo nixos-rebuild switch --flake 'path:.#{host}'")
    else:
        resources = InstallResources()
        try:
            # Recheck immediately before the first destructive command.
            validate_disk(data["disk"], data["home_size_gib"], data["swap_size_gib"], data["luks"])
            print_progress(1, 3, "Разметка и монтирование")
            format_and_mount(data["disk"], data["fs"], data["separate_home"], data["home_size_gib"],
                             data["swap_size_gib"], data["luks"], passphrase, resources=resources)
            luks_id, swap_id = capture_layout_ids(data["disk"], data["separate_home"], data["swap_size_gib"], data["luks"])
            write_meta(*basic, data["separate_home"], data["home_size_gib"], data["swap_size_gib"],
                       data["luks"], data["fs"], luks_id, swap_id, host_dir)
            print_progress(2, 3, "Hardware-конфигурация")
            generate_hardware_config()
            copy_hardware_config(hardware, swap_id)
            print_progress(3, 3, "Сборка и установка NixOS")
            install_system(host)
        finally:
            cleanup_mounts(resources)
        print("\nУстановка завершена. Можно перезагружаться.")
        print(f"Пользователь: {data['user']}. Пароль первого входа: nixos (если initialPassword не переопределён в meta.nix).")
        print("После входа смени пароль командой passwd. Пароль root установщик не задаёт.")
        print("Конфигурация установленной системы: /etc/nixos/nixdots")
        print(f"Лог: {log_file()}")
    if backup:
        print(f"Резервная копия: {backup}")
    return 0


def main() -> int:
    try:
        return execute()
    except KeyboardInterrupt:
        print("\nУстановка прервана пользователем.")
        return 130
    except Exception as error:
        print(f"\nОшибка установки: {redact(str(error))}")
        if common._LOG_FILE is not None:
            log_message(traceback.format_exc())
            print(f"Лог: {log_file()}")
        return 1
