# Запуск из NixOS Live ISO

Одна команда скачивает Bash-скрипт, который загружает проект, временно подключает
Git, Python и LVM через Nix и запускает установщик в режиме `live`:

```bash
curl -fsSL https://raw.githubusercontent.com/Redm00use/NixOS-Niri/main/scripts/install-live.sh -o /tmp/nixos-niri-install.sh && bash /tmp/nixos-niri-install.sh
```

Из уже скачанного проекта:

```bash
bash scripts/install-live.sh
```

Выбор диска, LVM, swap, отдельного `/home` и шифрования выполняется в меню.
Live-установка полностью стирает выбранный диск после подтверждения.
Нужны NixOS Live ISO, UEFI, x86_64 и интернет. Подробности: [INSTALL.md](INSTALL.md).
