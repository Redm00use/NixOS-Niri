from __future__ import annotations

import re
import sys


GPU_CHOICES = {"1": ("AMD", "amd"), "2": ("NVIDIA", "nvidia"), "3": ("Intel", "intel")}
FILESYSTEM_CHOICES = {"1": ("btrfs", "btrfs"), "2": ("ext4", "ext4")}
ROLE_CHOICES = {"1": ("desktop", "desktop"), "2": ("server", "server")}


def print_header(title: str, step: str | None = None) -> None:
    print()
    print("=" * 60)
    print(f"{step + ' — ' if step else ''}{title}")
    print("=" * 60)


def choose_from_menu(title: str, options: list[tuple[str, str]], default_key: str = "1") -> str:
    print_header(title)
    for key, label in options:
        print(f"{key}) {label}")
    while True:
        answer = input(f"Номер [{default_key}]: ").strip() or default_key
        for key, value in options:
            if answer == key:
                return value
        print("Неверный выбор, попробуй снова.")


def show_summary(title: str, rows: list[tuple[str, str]]) -> None:
    print_header(title)
    for key, value in rows:
        print(f"- {key:<16} {value}")


def prompt(label: str, default: str) -> str:
    value = input(f"{label} [{default}]: ").strip()
    return value or default


def validate_name(value: str, field_name: str) -> str:
    if not re.fullmatch(r"[a-z_][a-z0-9_-]*", value):
        print(f"Ошибка: {field_name} должно содержать только a-z, 0-9, _, - и начинаться с буквы или _.")
        sys.exit(1)
    return value


def choose_mode() -> str:
    return choose_from_menu("Режим установки", [("1", "config"), ("2", "live")], "1")


def choose_role() -> str:
    return choose_from_menu("Тип системы", [("1", "desktop"), ("2", "server")], "1")


def choose_gpu() -> str:
    return choose_from_menu("Выбор видеокарты", [(key, value) for key, (_, value) in GPU_CHOICES.items()], "1")


def choose_filesystem() -> str:
    return choose_from_menu("Файловая система root", [("1", "btrfs"), ("2", "ext4")], "1")


def choose_yes_no(label: str, default: bool = False) -> bool:
    suffix = "Y/n" if default else "y/N"
    answer = input(f"{label} [{suffix}]: ").strip().lower()
    if not answer:
        return default
    return answer in {"y", "yes", "д", "да"}


def prompt_int(label: str, default: int) -> int:
    value = input(f"{label} [{default}]: ").strip()
    if not value:
        return default
    try:
        parsed = int(value)
    except ValueError:
        print("Ошибка: нужно ввести число.")
        sys.exit(1)
    if parsed < 0:
        print("Ошибка: число должно быть >= 0.")
        sys.exit(1)
    return parsed


def prompt_passphrase() -> str:
    value = input("LUKS пароль (пусто = отмена): ").strip()
    if not value:
        print("Ошибка: пустой пароль для LUKS недопустим.")
        sys.exit(1)
    confirm_value = input("Повтори LUKS пароль: ").strip()
    if value != confirm_value:
        print("Ошибка: пароли не совпадают.")
        sys.exit(1)
    return value
