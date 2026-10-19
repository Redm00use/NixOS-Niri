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
        "x-scheme-handler/http" = [ "google-chrome-canary.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome-canary.desktop" ];
        "x-scheme-handler/about" = [ "google-chrome-canary.desktop" ];
        "x-scheme-handler/unknown" = [ "google-chrome-canary.desktop" ];
        "text/html" = [ "google-chrome-canary.desktop" ];
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
        path = "${config.home.homeDirectory}/nixos-config";
      };
    };
  };
}
