{
  inputs,
  config,
  pkgs,
  unstable,
  lib,
  role ? "desktop",
  userName ? "kotlin",
  ...
}:
let
  isDesktop = role == "desktop";
  noctaliaShellStore = "/nix/store/194mz2c31mhbqwcwshhks4cz5mkbjs88-noctalia-shell-2026-03-02_ba24387";
  noctaliaQuickshellStore = "/nix/store/k5m9m9fby1nprpa52vbpf10ym4kxx6kq-noctalia-qs-wrapped-0.0.1";
  patchedNoctaliaConfig = pkgs.runCommandLocal "noctalia-shell-config-no-bar-blur" { } ''
    cp -r ${inputs.noctalia} "$out"
    chmod -R u+w "$out"

    substituteInPlace "$out/Modules/Panels/Launcher/LauncherCore.qml" \
      --replace-fail 'color: entry.isSelected ? Color.mOnHover : Color.mOnSurfaceVariant' 'color: Color.mOnSurfaceVariant' \
      --replace-fail 'color: entry.isSelected ? Color.mOnHover : Color.mOnSurface' 'color: Color.mOnSurface' \
      --replace-fail 'color: gridEntryContainer.isSelected ? Color.mOnHover : Color.mOnSurface' 'color: Color.mOnSurface' \
      --replace-fail 'color: (entry.isSelected && !Settings.data.appLauncher.showIconBackground) ? Color.mOnHover : Color.mOnSurface' 'color: Color.mOnSurface' \
      --replace-fail 'color: (gridEntryContainer.isSelected && !Settings.data.appLauncher.showIconBackground) ? Color.mOnHover : Color.mOnSurface' 'color: Color.mOnSurface'

    cp ${./programs/noctalia/patches/LauncherCore.qml} "$out/Modules/Panels/Launcher/LauncherCore.qml"

    cp ${./programs/noctalia/patches/AllBackgrounds.qml} "$out/Modules/MainScreen/Backgrounds/AllBackgrounds.qml"
    cp ${./programs/noctalia/patches/MainScreen.qml} "$out/Modules/MainScreen/MainScreen.qml"
    cp ${./programs/noctalia/patches/BarContentWindow.qml} "$out/Modules/MainScreen/BarContentWindow.qml"
    cp ${./programs/noctalia/patches/Bar.qml} "$out/Modules/Bar/Bar.qml"

  '';
in
{
  imports = [
    ./programs
  ];

  home = {
    username = userName;
    homeDirectory = lib.mkForce "/home/${userName}";
    stateVersion = "25.05";
    packages =
      with pkgs;
      [
        gnome.gvfs
        nautilus
        bc
        imagemagick
        qimgv
        usbutils
        usbredir
        gpu-screen-recorder
        (writeShellApplication {
          name = "xfreerdp3";
          runtimeInputs = [ pkgs.freerdp ];
          text = ''
            exec xfreerdp "$@"
          '';
        })
        (writeShellApplication {
          name = "noctalia-shell-patched";
          text = ''
            exec ${noctaliaQuickshellStore}/bin/quickshell --path ${patchedNoctaliaConfig} "$@"
          '';
        })
      ]
      ++ lib.optionals isDesktop [
        unstable.gowall
        krita
        system-config-printer
        libreoffice
        pokemon-colorscripts
        android-tools
        obs-studio
        (writeShellApplication {
          name = "scrolllock_keyboard";
          runtimeInputs = [
            pkgs.brightnessctl
            pkgs.procps
          ];
          text = ''
            DEV="input*::scrolllock"
            STATE_FILE="/tmp/scrolllock_active"

            if [ -f "$STATE_FILE" ]; then
              rm "$STATE_FILE"
              pkill -f "scrolllock_daemon" || true
              brightnessctl --device="$DEV" set 0
              exit 0
            fi

            touch "$STATE_FILE"
            echo "none" | brightnessctl --device="$DEV" set 1

            (
              exec -a scrolllock_daemon sh -c '
                while [ -f /tmp/scrolllock_active ]; do
                  if [ "$(brightnessctl --device="input*::scrolllock" get)" -eq 0 ]; then
                    brightnessctl --device="input*::scrolllock" set 1
                  fi
                  sleep 0.2
                done
              '
            ) & disown
          '';
        })
      ];

    sessionVariables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
      QT_QPA_PLATFORM = "wayland;xcb";
      NIXOS_OZONE_WL = "1";
      XKB_DEFAULT_OPTIONS = "led:scroll";
    };

    file.".face".source = ../../assets/profile.png;
  };

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "application/x-gnome-saved-search" = [ "org.gnome.Nautilus.desktop" ];
        "x-scheme-handler/file" = [ "org.gnome.Nautilus.desktop" ];
        "x-scheme-handler/http" = [ "zen.desktop" ];
        "x-scheme-handler/https" = [ "zen.desktop" ];
        "x-scheme-handler/about" = [ "zen.desktop" ];
        "x-scheme-handler/unknown" = [ "zen.desktop" ];
        "text/html" = [ "zen.desktop" ];
      };
    };
  };

  nix.registry = {
    dev = {
      from = {
        id = "dev";
        type = "indirect";
      };
      to = {
        type = "path";
        path = "${config.home.homeDirectory}/nixdots";
      };
    };
  };
}
