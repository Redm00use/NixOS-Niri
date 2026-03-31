<div align="center">
	<img src="./assets/previews/preview-main.png" width="900px">
	<h1>NixOS Niri</h1>
	<p>NixOS configuration built around <b>niri</b>, <b>Noctalia</b>, <b>Home Manager</b>, and a portable <b>Python Installer</b>.</p>
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
		<td colspan="2" align="center">System Overview</td>
	</tr>
	<tr>
		<th>Component</th>
		<th>Value</th>
	</tr>
	<tr>
		<td>OS</td>
		<td>NixOS 25.11</td>
	</tr>
	<tr>
		<td>WM</td>
		<td>niri</td>
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
	<h3>📝 About</h3>
	<p>
	This is a portable <b>NixOS</b> setup for a desktop built on <b>niri</b> with <b>Home Manager</b>, <b>Noctalia</b>, dynamic host configs, and a built-in Python installer.
	</p>
	<h3>🚀 Features</h3>
	<p>
	• Wayland desktop powered by <b>niri</b><br>
	• Launcher, clipboard, wallpaper, and session menu through <b>Noctalia</b><br>
	• Dynamic flake hosts via <code>hosts/&lt;hostName&gt;</code><br>
	• Step-by-step Python installer for host generation and live install<br>
	• GPU selection: <b>AMD</b>, <b>NVIDIA</b>, <b>Intel</b><br>
	• Support for <b>LUKS</b>, swap, separate <code>/home</code>, and <b>btrfs</b> subvolumes<br>
	• Non-interactive mode for automation<br>
	</p>
</div>

> [!WARNING]
> Live installer mode fully wipes the selected disk.
> Always verify the target disk, partition layout, and `LUKS` / `swap` / `/home` options before installation.
> On a different machine you still need a hardware-specific `hardware-configuration.nix`.

## 📦 Installation

> [!IMPORTANT]
> Before running the installer, make sure `python3` is installed on the system.
>
> On a NixOS live environment, you can quickly get it with:
> ```bash
> nix-shell -p python3
> ```

### Interactive mode

```bash
python3 ./scripts/install.py
```

Installer now supports presets:

- `desktop-amd`
- `desktop-nvidia`
- `desktop-intel`
- `server`
- `custom`

### Full live installation

```bash
sudo python3 ./scripts/install.py
```

### Example non-interactive install

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

### Dry-run

```bash
sudo python3 ./scripts/install.py --mode live --host test --user me --gpu amd --fs btrfs --disk /dev/nvme0n1 --dry-run
```

### Export / import installer answers

```bash
python3 ./scripts/install.py --export-json install-profile.json
python3 ./scripts/install.py --import-json install-profile.json
```

### What the installer can do

1. Create a new host under `hosts/<hostName>`
2. Generate `meta.nix`
3. Partition and format a disk in live mode
4. Configure `EFI + root`
5. Optionally create `swap`
6. Optionally create a separate `/home`
7. Optionally enable `LUKS`
8. Create `btrfs` subvolumes
9. Save `PARTUUID` / `UUID` for runtime storage config
10. Create a backup of an existing `hosts/<hostName>` before overwrite
11. Show an install plan and check required tools before starting
12. Support presets and quick timezone / locale selection through menus
13. Write install logs to `.installer-logs/`
14. Export / import answers to `json`
15. Clean up mounts / swap on install failure

### Apply an existing host config

```bash
sudo nixos-rebuild switch --flake .#<hostName>
```

## ⌨️ Real Keybinds

`Mod` is the `Super` key.

| Action | Shortcut |
| --- | --- |
| Open terminal | `Mod+Return` |
| Toggle launcher | `Mod+A` |
| Open clipboard menu | `Mod+V` |
| Toggle wallpaper menu | `Mod+W` |
| Toggle session menu | `Mod+X` |
| Launch Zen Browser | `Mod+Z` |
| Open Nautilus | `Mod+E` |
| Open Zed | `Mod+C` |
| Open Telegram | `Mod+T` |
| Close window | `Mod+Q` |
| Toggle floating mode | `Mod+Space` |
| Toggle overview | `Mod+O` |
| Maximize column | `Mod+F` |
| Fullscreen window | `Mod+Shift+F` |
| Workspace 1..9 | `Mod+1..9` |
| Move to workspace 1..9 | `Mod+Shift+1..9` |
| Navigate windows / columns | `Mod+H / J / K / L` |
| Move windows / columns | `Mod+Ctrl+H / J / K / L` |
| Navigate monitors | `Mod+Shift+H / J / K / L` |
| Move column to monitor | `Mod+Shift+Ctrl+H / J / K / L` |
| Change column width | `Mod+=` / `Mod+-` |
| Change window height | `Mod+Shift+=` / `Mod+Shift+-` |
| Screenshot | `Mod+Alt+Shift+4` |
| Show hotkey overlay | `Mod+Shift+Slash` |
| Power off monitors | `Mod+Shift+P` |
| Quit `niri` | `Ctrl+Alt+Delete` / `Mod+Shift+E` |
| Scroll Lock helper | `Scroll_Lock` |

## 🗂️ Project Layout

- `flake.nix` — flake entry and automatic host discovery
- `lib/mkHost.nix` — host builder from metadata
- `hosts/<hostName>` — host-specific files
- `modules/system` — system modules
- `modules/home` — Home Manager modules
- `scripts/install.py` — installer entrypoint
- `scripts/installer` — modular installer implementation

## 📝 Notes

- `meta.nix` stores `hostName`, `userName`, `gpuType`, `role`, `timeZone`, `defaultLocale`, and storage metadata
- runtime storage behavior is extended by `modules/system/profiles/storage/default.nix`
- keyboard layout is `us,ru`, switched with `Caps Lock`
