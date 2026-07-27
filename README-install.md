# NixOS Installer

Основная точка входа:

```bash
python3 ./scripts/install.py
```

По умолчанию это встроенный пошаговый TUI без внешних зависимостей.

Структура Python installer:
- `scripts/installer/cli.py` — основной сценарий
- `scripts/installer/prompts.py` — интерактивные вопросы и валидация
- `scripts/installer/disk.py` — разметка, форматирование, mount, install
- `scripts/installer/meta.py` — генерация `hosts/<host>/meta.nix`
- `scripts/installer/common.py` — общие пути, логирование и shell helpers

## Два режима

| Режим | Что делает | Нужен root |
| --- | --- | --- |
| `--mode config` | только генерирует `hosts/<host>/meta.nix` | нет |
| `--mode live` | размечает диск и ставит систему | да |

В режиме `config` не требуются ни `parted`, ни `nixos-install`: проверка утилит
выполняется только для `live` и только для реально выбранной ФС и LUKS.

## Флаги

```
--mode {config,live}
--user <name>              имя пользователя (POSIX: [a-z_][a-z0-9_-]{0,31})
--host <name>              имя хоста (RFC 1035, до 63 символов)
--role {desktop,server}
--timezone <tz>
--locale <locale>
--gpu {amd,nvidia,intel,vm}
--fs {btrfs,ext4}
--disk /dev/nvme0n1
--separate-home
--home-size-gib <N>
--swap-size-gib <N>        0 = без swap-раздела
--luks
--luks-passphrase-file <path>
--luks-passphrase <str>    небезопасно, видно в ps
--yes                      не задавать ни одного вопроса
--dry-run                  показать план и выйти
--export-json <path>
--import-json <path>
```

### Имена хостов

Имя хоста должно быть корректным DNS-лейблом (RFC 1035): буквы, цифры и дефис
внутри, без точек и подчёркиваний. Имена `common` и `generated` зарезервированы:
это служебные каталоги в `hosts/`.

## Полностью неинтерактивная установка

`--yes` теперь действительно не задаёт вопросов — включая подтверждение диска,
на котором раньше автоматизация зависала. Поэтому в live-режиме с `--yes`
диск обязательно задаётся явно через `--disk`.

```bash
printf '%s' 'super-secret' > /run/luks.key
sudo python3 ./scripts/install.py \
  --mode live \
  --user kotlin \
  --host niri \
  --role desktop \
  --gpu amd \
  --fs btrfs \
  --disk /dev/nvme0n1 \
  --swap-size-gib 8 \
  --luks \
  --luks-passphrase-file /run/luks.key \
  --yes
shred -u /run/luks.key
```

## LUKS-пароль

Пароль передаётся в `cryptsetup` только через stdin (`--key-file -`). Он не попадает
ни в `argv`, ни в `ps`, ни в лог установки (в логе он заменяется на `********`).

Приоритет источников: `--luks-passphrase-file` → `--luks-passphrase` (с предупреждением)
→ интерактивный ввод через `getpass` (без эха, с повтором).

При включённом LUKS `boot.resumeDevice` **не** настраивается: swap-раздел остаётся
незашифрованным, а образ гибернации содержит ключи шифрования root.

## Пароли после установки

`nixos-install` вызывается с `--no-root-passwd`, иначе он в конце ждёт интерактивный
ввод и любая автоматизация виснет. Следствия:

- у `root` пароля нет, вход под root невозможен;
- входи под обычным пользователем с `initialPassword` (по умолчанию `nixos`);
- сразу после первого входа смени пароль: `passwd`;
- при необходимости задай root: `sudo passwd root`.

`initialPassword` переопределяется в `hosts/<host>/meta.nix`. Раньше он был зашит в код
и одинаков у всех, кто клонировал репозиторий.

## Backup’ы и логи

- резервные копии `hosts/<host>/` и `hardware-configuration.nix` кладутся в `.installer-backups/`,
  а не рядом в `hosts/` — иначе flake пытался собирать `myhost.backup-...` как хост;
- лог установки пишется в `.installer-logs/`, а если репозиторий только для чтения —
  во временную директорию;
- оба каталога в `.gitignore` и не копируются в установленную систему.

## Если установка упала

Инсталлер показывает причину, пишет traceback в лог, размонтирует `/mnt`,
выключает swap и закрывает LUKS-маппинг. После этого можно сразу запускать
его заново — раньше повторный запуск падал на `device is busy`.
