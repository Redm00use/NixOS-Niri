# NixOS Niri

[English version](./README.en.md)

`NixOS` • `niri` • `Home Manager` • `Noctalia` • `Python Installer`

Современный конфиг `NixOS` на базе `niri`, `Home Manager`, `Noctalia` и переносимого Python-инсталлера для генерации host-конфигов и полной live-установки.

## Превью

![Превью](./assets/previews/preview-main.png)

## Что есть

- рабочее окружение на `niri`
- `Noctalia` для лаунчера, буфера обмена, обоев и power menu
- динамические flake-host'ы из `hosts/<hostName>`
- встроенный Python installer с пошаговым TUI
- полноценная live-установка NixOS
- выбор GPU: `AMD`, `NVIDIA`, `Intel`
- опциональные `LUKS`, swap, отдельный `/home`, `btrfs` subvolumes
- non-interactive режим для автоматизации

## Основной стек

- **WM** — `niri`
- **Shell** — `zsh`
- **Terminal** — `wezterm`
- **Panel / Launcher** — `Noctalia`
- **Browser** — `Zen Browser`
- **File Manager** — `Nautilus`
- **Editor** — `Zed` / `Neovim`

## Реальные хоткеи

`Mod` — это клавиша `Super`.

| Комбинация | Действие |
| --- | --- |
| `Mod+Return` | Открыть `wezterm` |
| `Mod+A` | Открыть / закрыть лаунчер Noctalia |
| `Mod+V` | Открыть менеджер буфера обмена |
| `Mod+W` | Открыть / закрыть меню обоев |
| `Mod+X` | Открыть / закрыть меню сессии / питания |
| `Mod+Z` | Запустить Zen Browser |
| `Mod+E` | Открыть Nautilus |
| `Mod+C` | Открыть Zed |
| `Mod+T` | Открыть Telegram |
| `Mod+Q` | Закрыть текущее окно |
| `Mod+Space` | Переключить floating mode |
| `Mod+O` | Переключить overview |
| `Mod+F` | Развернуть колонку |
| `Mod+Shift+F` | Полный экран |
| `Mod+1..9` | Переключение на workspace 1..9 |
| `Mod+Shift+1..9` | Перенести колонку в workspace 1..9 |
| `Mod+H / J / K / L` | Навигация по окнам / колонкам |
| `Mod+Ctrl+H / J / K / L` | Перемещение колонок / окон |
| `Mod+Shift+H / J / K / L` | Переключение между мониторами |
| `Mod+Shift+Ctrl+H / J / K / L` | Перенос колонки на другой монитор |
| `Mod+R` | Переключить preset ширины колонки |
| `Mod+Shift+R` | Переключить preset высоты окна |
| `Mod+=` / `Mod+-` | Изменить ширину колонки |
| `Mod+Shift+=` / `Mod+Shift+-` | Изменить высоту окна |
| `Mod+Alt+Shift+4` | Скриншот |
| `Mod+Shift+Slash` | Показать overlay с хоткеями |
| `Mod+Shift+P` | Выключить мониторы |
| `Ctrl+Alt+Delete` | Выйти из `niri` |
| `Mod+Shift+E` | Выйти из `niri` |
| `Scroll_Lock` | Переключить helper для scroll lock |

## Установщик

Интерактивный режим:

```bash
python3 ./scripts/install.py
```

Live-установка:

```bash
sudo python3 ./scripts/install.py
```

Пример non-interactive установки:

```bash
sudo python3 ./scripts/install.py \
  --mode live \
  --host mypc \
  --user me \
  --role desktop \
  --timezone Europe/Kyiv \
  --locale ru_RU.UTF-8 \
  --gpu amd \
  --fs btrfs \
  --disk /dev/nvme0n1 \
  --swap-size-gib 8 \
  --yes
```

## Что умеет installer

- создать новый host в `hosts/<hostName>`
- сгенерировать `meta.nix`
- разметить и отформатировать диск
- настроить `EFI + root`
- опционально создать `swap`
- опционально создать отдельный `/home`
- опционально включить `LUKS`
- создать `btrfs` subvolumes
- сохранить `PARTUUID` / `UUID` для runtime storage-конфига

## Применение конфига

```bash
sudo nixos-rebuild switch --flake .#<hostName>
```

## Структура проекта

- `flake.nix` — flake entry и автоматическое обнаружение host'ов
- `lib/mkHost.nix` — сборка host-конфига из metadata
- `hosts/<hostName>` — host-specific файлы
- `modules/system` — системные модули
- `modules/home` — модули Home Manager
- `scripts/install.py` — точка входа installer'а
- `scripts/installer` — модульная реализация installer'а

## Примечания

- `meta.nix` хранит `hostName`, `userName`, `gpuType`, `role`, `timeZone`, `defaultLocale` и storage-метаданные
- runtime storage-логика расширяется через `modules/system/profiles/storage/default.nix`
- раскладка клавиатуры — `us,ru`, переключение через `Caps Lock`
