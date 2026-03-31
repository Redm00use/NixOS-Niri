# NixOS Niri

[Русская версия](./README.ru.md)

Modern NixOS configuration built around `niri`, `Home Manager`, `Noctalia`, and a portable Python installer for both host generation and full live installation.

## Preview

![Preview](./assets/previews/preview-main.png)

## Highlights

- `niri` Wayland desktop
- `Noctalia` shell / launcher / clipboard / wallpaper menu
- dynamic flake hosts from `hosts/<hostName>`
- built-in Python installer with interactive TUI
- full live-install flow for NixOS
- GPU selection: `AMD`, `NVIDIA`, `Intel`
- optional `LUKS`, swap, separate `/home`, `btrfs` subvolumes
- non-interactive installer mode for automation

## Stack

- **WM** — `niri`
- **Shell** — `zsh`
- **Terminal** — `wezterm`
- **Panel / Launcher** — `Noctalia`
- **Browser** — `Zen Browser`
- **File Manager** — `Nautilus`
- **Editor** — `Zed` / `Neovim`

## Real Keybinds

`Mod` is the `Super` key.

| Shortcut | Action |
| --- | --- |
| `Mod+Return` | Open `wezterm` |
| `Mod+A` | Toggle Noctalia launcher |
| `Mod+V` | Open clipboard menu |
| `Mod+W` | Toggle wallpaper panel |
| `Mod+X` | Toggle session / power menu |
| `Mod+Z` | Launch Zen Browser |
| `Mod+E` | Open Nautilus |
| `Mod+C` | Open Zed |
| `Mod+T` | Open Telegram |
| `Mod+Q` | Close focused window |
| `Mod+Space` | Toggle floating mode |
| `Mod+O` | Toggle overview |
| `Mod+F` | Maximize column |
| `Mod+Shift+F` | Fullscreen window |
| `Mod+1..9` | Focus workspace 1..9 |
| `Mod+Shift+1..9` | Move column to workspace 1..9 |
| `Mod+H / J / K / L` | Navigate left / down / up / right |
| `Mod+Ctrl+H / J / K / L` | Move column / window |
| `Mod+Shift+H / J / K / L` | Focus monitor |
| `Mod+Shift+Ctrl+H / J / K / L` | Move column to monitor |
| `Mod+R` | Switch preset column width |
| `Mod+Shift+R` | Switch preset window height |
| `Mod+=` / `Mod+-` | Adjust column width |
| `Mod+Shift+=` / `Mod+Shift+-` | Adjust window height |
| `Mod+Alt+Shift+4` | Screenshot |
| `Mod+Shift+Slash` | Show hotkey overlay |
| `Mod+Shift+P` | Power off monitors |
| `Ctrl+Alt+Delete` | Quit niri |
| `Mod+Shift+E` | Quit niri |
| `Scroll_Lock` | Toggle scroll lock keyboard helper |

## Installer

Interactive mode:

```bash
python3 ./scripts/install.py
```

Live install:

```bash
sudo python3 ./scripts/install.py
```

Example non-interactive install:

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

## What the installer can do

- create a new host under `hosts/<hostName>`
- generate `meta.nix`
- partition and format disk for live install
- configure `EFI + root`
- optionally create `swap`
- optionally create separate `/home`
- optionally enable `LUKS`
- create `btrfs` subvolumes when needed
- capture `PARTUUID` / `UUID` for runtime storage config

## Apply Config

```bash
sudo nixos-rebuild switch --flake .#<hostName>
```

## Project Layout

- `flake.nix` — flake entry and dynamic host discovery
- `lib/mkHost.nix` — host builder from metadata
- `hosts/<hostName>` — host-specific files
- `modules/system` — system configuration
- `modules/home` — home-manager configuration
- `scripts/install.py` — installer entrypoint
- `scripts/installer` — modular installer implementation

## Notes

- `meta.nix` stores `hostName`, `userName`, `gpuType`, `role`, `timeZone`, `defaultLocale`, and storage metadata.
- runtime storage behavior is extended by `modules/system/profiles/storage/default.nix`
- keyboard layout is `us,ru` with `Caps Lock` switching layouts

## Russian README

- `README.ru.md`
