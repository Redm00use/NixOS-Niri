<div align="center">
	<img src="./assets/previews/preview-main.png" width="900px">
	<h1>NixOS Niri</h1>
	<p>Конфиг NixOS на базе <b>niri</b>, <b>Noctalia</b>, <b>Home Manager</b> и переносимого <b>Python Installer</b>.</p>
	<a href="./README.md">
		<img src="https://img.shields.io/badge/README-RU-cba6f7?style=for-the-badge&labelColor=1C2325">
	</a>
	<a href="./README.en.md">
		<img src="https://img.shields.io/badge/README-ENG-89b4fa?style=for-the-badge&labelColor=1C2325">
	</a>
</div>

***

<table align="right">
	<tr>
		<td colspan="2" align="center">Системные параметры</td>
	</tr>
	<tr>
		<th>Компонент</th>
		<th>Значение</th>
	</tr>
	<tr>
		<td>OS</td>
		<td>NixOS 25.11</td>
	</tr>
	<tr>
		<td>WM</td>
		<td>niri 26.04 (stable)</td>
	</tr>
	<tr>
		<td>Shell</td>
		<td>zsh</td>
	</tr>
	<tr>
		<td>Terminal</td>
		<td>wezterm</td>
	</tr>
	<tr>
		<td>Panel</td>
		<td>Noctalia</td>
	</tr>
	<tr>
		<td>Browser</td>
		<td>Zen Browser</td>
	</tr>
	<tr>
		<td>File Manager</td>
		<td>Nautilus</td>
	</tr>
	<tr>
		<td>Editor</td>
		<td>Zed / Neovim</td>
	</tr>
	<tr>
		<td>Audio</td>
		<td>PipeWire</td>
	</tr>
	<tr>
		<td>Bootloader</td>
		<td>systemd-boot</td>
	</tr>
	<tr>
		<td>Theming</td>
		<td>Stylix</td>
	</tr>
	<tr>
		<td>Installer</td>
		<td>Python TUI</td>
	</tr>
</table>

<div align="left">
	<h3>📝 О проекте</h3>
	<p>
	Это переносимый конфиг <b>NixOS</b> для рабочего окружения на <b>niri</b> с интеграцией <b>Home Manager</b>, <b>Noctalia</b>, динамическими host-конфигами и встроенным Python-инсталлером.
	</p>
	<h3>🚀 Возможности</h3>
	<p>
	• Рабочее окружение на <b>niri</b> под Wayland<br>
	• Лаунчер, clipboard, wallpaper и session menu через <b>Noctalia</b><br>
	• Динамические flake-host'ы через <code>hosts/&lt;hostName&gt;</code><br>
	• Пошаговый Python installer для генерации host-конфига и live-установки<br>
	• Выбор GPU: <b>AMD</b>, <b>NVIDIA</b>, <b>Intel</b><br>
	• Поддержка <b>LUKS</b>, swap, отдельного <code>/home</code>, <b>btrfs</b> subvolumes<br>
	• Non-interactive режим для автоматизации установки<br>
	</p>
</div>

> [!WARNING]
> Live-режим инсталлера полностью стирает выбранный диск.
> Перед установкой обязательно проверь правильность диска, схемы разделов и параметров `LUKS` / `swap` / `/home`.
> Для другого ПК нужно пересоздавать `hardware-configuration.nix` под конкретное железо.
> Для виртуальной машины можно выбрать отдельный GPU-режим `vm`.

## 📦 Установка

Установщик запускается из Live USB и за один проход устанавливает NixOS вместе
с этим конфигом. Предварительно установленная NixOS не нужна. Используй Live ISO
в режиме UEFI на x86_64 и подключи интернет для загрузки flake и пакетов.

> [!CAUTION]
> Live-установка полностью стирает выбранный диск. Перед подтверждением проверь
> имя диска и план разметки. На другом компьютере создаётся новый
> `hardware-configuration.nix` под его оборудование.

В NixOS Live запусти установщик так (команда временно добавит Python и LVM):

```bash
sudo nix-shell -p python3 lvm2 --run 'python3 scripts/install.py'
```

Выбери режим `live`, имя пользователя и хоста, видеокарту, файловую систему и
диск. Затем установщик спросит, включать ли LVM и LUKS, сколько выделить swap и
создавать ли отдельный `/home`. После проверки плана нужно подтвердить стирание
диска словом `ERASE`. Сборка и установка могут занять 20–40 минут.

### Разметка диска

Можно выбрать ext4 или btrfs. Без LVM установщик создаёт EFI, root и опциональные
разделы swap и `/home`. В btrfs root и домашние данные используют подтома `@` и
`@home`.

С LVM создаются EFI-раздел и PV с VG `nixdots`. Root занимает оставшееся место;
swap и отдельный `/home` создаются как логические тома по выбранным размерам.
Укажи любой размер swap в GiB, который помещается на диске; `0` отключает
дисковый swap. Настроенный отдельно zram при этом продолжает работать.

LUKS без LVM шифрует root. При сочетании LVM и LUKS шифруется весь PV, включая
root, swap и отдельный `/home`. Автоматический resume из гибернации с LUKS не
включается. Если включён LUKS, установщик запросит пароль; для автоматизации его
можно передать файлом через `--luks-passphrase-file`.

### Установка с параметрами

Пример для LVM, swap 32 GiB и общего root/home:

```bash
sudo nix-shell -p python3 lvm2 --run 'python3 scripts/install.py --mode live --host mypc --user me --gpu amd --disk /dev/nvme0n1 --lvm --swap-size-gib 32 --no-separate-home --yes'
```

Добавь `--separate-home --home-size-gib 200`, чтобы создать отдельный `/home`.
Для установки без LVM используй `--no-lvm`; `--swap-size-gib 0` отключает
дисковый swap. С `--yes` установщик не спрашивает подтверждение стирания диска,
поэтому сначала просмотри план через `--dry-run`:

```bash
sudo nix-shell -p python3 lvm2 --run 'python3 scripts/install.py --mode live --host test --user me --gpu amd --disk /dev/nvme0n1 --lvm --swap-size-gib 32 --yes --dry-run'
```

Для LUKS в автоматическом режиме добавь `--luks --luks-passphrase-file /путь/к/файлу`.
Не передавай пароль непосредственно через `--luks-passphrase`: он может быть
виден в списке процессов и истории оболочки.

### Только генерация host-конфига

Если NixOS уже установлена, создай host без разметки диска:

```bash
python3 scripts/install.py --mode config --host mypc --user me --role desktop --timezone Europe/Kyiv --locale ru_RU.UTF-8 --gpu amd --yes
```

Проверь и замени `hosts/mypc/hardware-configuration.nix` конфигурацией текущего
компьютера, затем собери систему:

```bash
sudo nixos-rebuild switch --flake 'path:.#mypc'
```

Установщик поддерживает пресеты `desktop-amd`, `desktop-nvidia`, `desktop-intel`,
`vm`, `server` и `custom`. Ответы можно переносить через `--export-json` и
`--import-json`. Перед изменением существующего host создаётся резервная копия в
`.installer-backups/`; журнал установки находится в `.installer-logs/`.

После установки войди под созданным пользователем и смени начальный пароль
командой `passwd`.

### Noctalia v5

Desktop-профиль устанавливает Noctalia v5.2.0 с меню приложений в виде сетки.
Панель показывает рабочие столы слева, активное приложение по центру и
уведомления, громкость, Bluetooth, раскладку и часы справа. Конфигурация сохраняет
палитру Original; старые Noctalia v4 QML-патчи и noctalia-qs удалены.

## ⌨️ Реальные хоткеи

`Mod` — это клавиша `Super`.

| Действие | Комбинация |
| --- | --- |
| Открыть терминал | `Mod+Return` |
| Открыть / закрыть лаунчер | `Mod+A` |
| Открыть clipboard menu | `Mod+V` |
| Открыть / закрыть меню обоев | `Mod+W` |
| Открыть / закрыть session menu | `Mod+X` |
| Запустить Zen Browser | `Mod+Z` |
| Открыть Nautilus | `Mod+E` |
| Открыть Zed | `Mod+C` |
| Открыть Telegram | `Mod+T` |
| Закрыть окно | `Mod+Q` |
| Переключить floating mode | `Mod+Space` |
| Переключить overview | `Mod+O` |
| Развернуть колонку | `Mod+F` |
| Полный экран | `Mod+Shift+F` |
| Workspace 1..9 | `Mod+1..9` |
| Перенос в workspace 1..9 | `Mod+Shift+1..9` |
| Навигация по окнам/колонкам | `Mod+H / J / K / L` |
| Перемещение колонок/окон | `Mod+Ctrl+H / J / K / L` |
| Навигация по мониторам | `Mod+Shift+H / J / K / L` |
| Перенос колонки на монитор | `Mod+Shift+Ctrl+H / J / K / L` |
| Изменить ширину колонки | `Mod+=` / `Mod+-` |
| Изменить высоту окна | `Mod+Shift+=` / `Mod+Shift+-` |
| Скриншот | `Mod+Alt+Shift+4` |
| Overlay с хоткеями | `Mod+Shift+Slash` |
| Выключить мониторы | `Mod+Shift+P` |
| Выйти из `niri` | `Ctrl+Alt+Delete` / `Mod+Shift+E` |
| Scroll Lock helper | `Scroll_Lock` |

## 🗂️ Структура проекта

- `flake.nix` — flake entry и автоматическое обнаружение host'ов
- `lib/mkHost.nix` — сборка host-конфига из metadata
- `hosts/<hostName>` — host-specific файлы
- `modules/system` — системные модули
- `modules/home` — модули Home Manager
- `scripts/install.py` — точка входа installer'а
- `scripts/installer` — модульная реализация installer'а

## 📝 Примечания

- `meta.nix` хранит `hostName`, `userName`, `gpuType`, `role`, `timeZone`, `defaultLocale` и storage-метаданные
- runtime storage-логика расширяется через `modules/system/profiles/storage/default.nix`
- раскладка клавиатуры — `us,ru`, переключение через `Caps Lock`
