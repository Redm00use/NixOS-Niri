from __future__ import annotations

import getpass
import re
import sys


GPU_CHOICES = {"1": ("AMD", "amd"), "2": ("NVIDIA", "nvidia"), "3": ("Intel", "intel"), "4": ("VM", "vm")}
GPU_VALUES = [value for _, value in GPU_CHOICES.values()]
FILESYSTEM_CHOICES = {"1": ("btrfs", "btrfs"), "2": ("ext4", "ext4")}
ROLE_CHOICES = {"1": ("desktop", "desktop"), "2": ("server", "server")}
TIMEZONE_CHOICES = {
    "1": ("Europe/Kyiv", "Europe/Kyiv"),
    "2": ("Europe/Moscow", "Europe/Moscow"),
    "3": ("UTC", "UTC"),
}
LOCALE_CHOICES = {
    "1": ("ru_RU.UTF-8", "ru_RU.UTF-8"),
    "2": ("en_US.UTF-8", "en_US.UTF-8"),
    "3": ("uk_UA.UTF-8", "uk_UA.UTF-8"),
}
PRESET_CHOICES = {
    "1": ("desktop-amd", "desktop-amd"),
    "2": ("desktop-nvidia", "desktop-nvidia"),
    "3": ("desktop-intel", "desktop-intel"),
    "4": ("vm", "vm"),
    "5": ("server", "server"),
    "6": ("custom", "custom"),
}

# hosts/common и hosts/generated — служебные каталоги, а не хосты.
RESERVED_HOST_NAMES = {"common", "generated"}


def require_tty(what: str) -> None:
    if not sys.stdin.isatty():
        print(f"Ошибка: нужен интерактивный ввод ({what}), но stdin не является терминалом.")
        print("Передай значение аргументом CLI или через --import-json.")
        sys.exit(1)


def ask(label: str) -> str:
    require_tty(label.strip())
    return input(label)


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
        answer = ask(f"Номер [{default_key}]: ").strip() or default_key
        for key, value in options:
            if answer == key:
                return value
        print("Неверный выбор, попробуй снова.")


def show_summary(title: str, rows: list[tuple[str, str]]) -> None:
    print_header(title)
    for key, value in rows:
        print(f"- {key:<16} {value}")


def prompt(label: str, default: str) -> str:
    value = ask(f"{label} [{default}]: ").strip()
    return value or default


def validate_user_name(value: str) -> str:
    """Проверить имя пользователя по правилам useradd."""
    if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,31}", value):
        print("Ошибка: имя пользователя должно быть в нижнем регистре, начинаться с буквы или '_',")
        print("содержать только a-z, 0-9, '_', '-' и быть не длиннее 32 символов.")
        sys.exit(1)
    return value


def validate_host_name(value: str) -> str:
    """Проверить имя хоста как DNS-метку (RFC 1035).

    networking.hostName в NixOS не принимает '_' и имена, начинающиеся с '-',
    поэтому старая проверка пропускала конфиги, которые падали при сборке.
    """
    if len(value) > 63 or not re.fullmatch(r"[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?", value):
        print("Ошибка: имя хоста должно быть валидной DNS-меткой (RFC 1035):")
        print("только a-z, A-Z, 0-9 и '-', начинаться и заканчиваться буквой или цифрой, до 63 символов.")
        print("Символ '_' в имени хоста недопустим — NixOS отклонит такой networking.hostName.")
        sys.exit(1)
    if value in RESERVED_HOST_NAMES:
        print(f"Ошибка: имя хоста '{value}' зарезервировано — hosts/{value} служебный каталог.")
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


def choose_timezone() -> str:
    return choose_from_menu("Часовой пояс", [(key, value) for key, (_, value) in TIMEZONE_CHOICES.items()], "1")


def choose_locale() -> str:
    return choose_from_menu("Locale", [(key, value) for key, (_, value) in LOCALE_CHOICES.items()], "1")


def choose_preset() -> str:
    # По умолчанию 'custom': это desktop-конфиг, молча выбирать 'server' неправильно.
    return choose_from_menu("Preset конфигурации", [(key, value) for key, (_, value) in PRESET_CHOICES.items()], "6")


def choose_yes_no(label: str, default: bool = False) -> bool:
    suffix = "Y/n" if default else "y/N"
    answer = ask(f"{label} [{suffix}]: ").strip().lower()
    if not answer:
        return default
    return answer in {"y", "yes", "д", "да"}


def prompt_int(label: str, default: int) -> int:
    value = ask(f"{label} [{default}]: ").strip()
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
    """Спросить LUKS-пароль без эха.

    Пароль не обрезается через strip(): пробелы — часть пароля.
    """
    require_tty("LUKS-пароль")
    value = getpass.getpass("LUKS пароль (ввод скрыт): ")
    if not value:
        print("Ошибка: пустой пароль для LUKS недопустим.")
        sys.exit(1)
    if len(value) < 8:
        print("Предупреждение: пароль короче 8 символов.")
    confirm_value = getpass.getpass("Повтори LUKS пароль: ")
    if value != confirm_value:
        print("Ошибка: пароли не совпадают.")
        sys.exit(1)
    return value
