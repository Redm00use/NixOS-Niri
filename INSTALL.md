# Установка

Запуск:

```bash
python3 ./scripts/install.py
```

Неинтерактивный режим тоже есть. Пример генерации host-конфига:

```bash
python3 ./scripts/install.py --mode config --host mypc --user me --role desktop --timezone Europe/Kyiv --locale ru_RU.UTF-8 --gpu amd --yes
```

Пример live-установки:

```bash
sudo python3 ./scripts/install.py --mode live --host mypc --user me --role desktop --timezone Europe/Kyiv --locale ru_RU.UTF-8 --gpu amd --fs btrfs --disk /dev/nvme0n1 --swap-size-gib 8 --yes
```

Для live-режима запускай от `root`:

```bash
sudo python3 ./scripts/install.py
```

Установщик умеет два режима:
- только сгенерировать config
- полная live-установка NixOS

Он спрашивает:
- имя пользователя
- имя хоста
- роль: `desktop` / `server`
- timezone
- locale
- видеокарту: AMD / NVIDIA / Intel
- подтверждение выбора

Для live-установки дополнительно:
- выбор диска
- выбор файловой системы root: `btrfs` или `ext4`
- отдельный `/home`
- размер `/home`
- размер `swap`
- включение `LUKS`
- явное подтверждение стирания диска

После этого обновляется `hosts/<hostName>/meta.nix`.

Имя хоста теперь одновременно используется как имя каталога в `hosts/<hostName>` и как flake target.

Сборка:

```bash
sudo nixos-rebuild switch --flake .#<hostName>
```

В live-режиме скрипт сам:
- размечает диск GPT
- создаёт EFI-раздел и root-раздел
- при выборе создаёт отдельные разделы `swap` и `/home`
- форматирует разделы
- умеет шифровать `root` через `LUKS`
- монтирует `/mnt`
- запускает `nixos-generate-config`
- копирует репозиторий в `/mnt/etc/nixos/nixdots`
- запускает `nixos-install`

Важно: live-режим полностью стирает выбранный диск.

`meta.nix` теперь также влияет на runtime storage-настройки через `modules/system/profiles/storage/default.nix`.
После live-установки инсталлер автоматически сохраняет `PARTUUID` для LUKS-root и `UUID` для swap, чтобы Nix мог настроить `boot.initrd.luks.devices` и `boot.resumeDevice`.
