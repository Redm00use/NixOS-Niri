# NixOS Niri

Portable NixOS configuration for `niri` with dynamic hosts, Home Manager integration, GPU selection, and a built-in Python installer for both config generation and live installation.

## Preview

![Preview](./assets/previews/preview-main.png)

## Features

- `niri` + `Noctalia` desktop setup
- dynamic flake hosts from `hosts/<hostName>`
- user/host/GPU parametrization through `meta.nix`
- built-in Python installer with interactive TUI
- live-install mode with disk partitioning
- support for `AMD`, `NVIDIA`, `Intel`
- optional `LUKS`, separate `/home`, swap, `btrfs` subvolumes
- non-interactive installer flags for automation

## Main Components

- **Window Manager** — `niri`
- **Shell** — `zsh`
- **Terminal** — `wezterm`
- **Panel / Launcher** — `Noctalia`
- **Editor** — `Neovim`
- **File Manager** — `Yazi` / `Nautilus`

## Installer

Main entrypoint:

```bash
python3 ./scripts/install.py
```

Live install:

```bash
sudo python3 ./scripts/install.py
```

Non-interactive example:

```bash
sudo python3 ./scripts/install.py --mode live --host mypc --user me --role desktop --timezone Europe/Kyiv --locale ru_RU.UTF-8 --gpu amd --fs btrfs --disk /dev/nvme0n1 --swap-size-gib 8 --yes
```

## Apply Existing Host

```bash
sudo nixos-rebuild switch --flake .#<hostName>
```

## Structure

- `flake.nix` — flake entry and host discovery
- `lib/mkHost.nix` — host builder with meta parameters
- `hosts/<hostName>` — per-host config and metadata
- `modules/system` — system modules
- `modules/home` — home-manager modules
- `scripts/install.py` — installer entrypoint
- `scripts/installer` — modular installer implementation

## Notes

- `meta.nix` controls `hostName`, `userName`, `gpuType`, `role`, `timeZone`, `defaultLocale` and storage-related metadata.
- Live installer can automatically persist `PARTUUID` and `UUID` for LUKS and swap.
- Runtime storage behavior is supplemented by `modules/system/profiles/storage/default.nix`.
