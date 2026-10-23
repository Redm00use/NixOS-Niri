#!/usr/bin/env bash
set -euo pipefail

# Run locally or download this file and run it with Bash in NixOS Live.
if [[ ${1:-} != --prepared ]]; then
  if ! command -v nix-shell >/dev/null 2>&1; then
    printf '%s\n' 'Запусти этот скрипт из NixOS Live ISO: требуется nix-shell.' >&2
    exit 1
  fi
  script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
  script_path="$script_dir/$(basename -- "${BASH_SOURCE[0]}")"
  printf -v launch '%q ' bash "$script_path" --prepared "$@"
  printf '%s\n' 'Подключение Git, Python и LVM во временном Nix-окружении…'
  exec nix-shell -p git python3 lvm2 --run "$launch"
fi
shift

# A piped download must not consume the installer's interactive input.
if [[ ! -t 0 ]]; then
  if ! { exec </dev/tty; }; then
    printf '%s\n' 'Для интерактивной установки нужен терминал.' >&2
    exit 1
  fi
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$script_dir/.." && pwd)
if [[ ! -f "$repo_dir/flake.nix" || ! -f "$repo_dir/scripts/install.py" ]]; then
  download_dir=$(mktemp -d "${TMPDIR:-/tmp}/nixos-niri.XXXXXX")
  repo_dir="$download_dir/source"
  printf '%s\n' 'Загрузка NixOS-Niri из ветки main…'
  git clone --depth 1 --branch main --single-branch \
    https://github.com/Redm00use/NixOS-Niri.git "$repo_dir"
fi

cd -- "$repo_dir"
printf '%s\n' 'Запуск Live-установщика. Диск будет выбран и подтверждён в меню.'
if (( EUID == 0 )); then
  exec python3 scripts/install.py --mode live "$@"
else
  exec sudo env "PATH=$PATH" python3 scripts/install.py --mode live "$@"
fi
