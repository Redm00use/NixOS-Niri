{
  config,
  pkgs,
  unstable,
  lib,
  role ? "desktop",
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
    username = "vitor";
    homeDirectory = lib.mkForce "/home/vitor";
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
        prismlauncher
        (writeShellApplication {
          name = "minecraft";
          runtimeInputs = [
            gamemode
            prismlauncher
            util-linux
          ];
          text = ''
            exec taskset -c 0-3 gamemoderun prismlauncher
          '';
        })
      ]
      ++ lib.optionals isDesktop [
        unstable.gowall
        krita
        system-config-printer
        libreoffice
        pokemon-colorscripts
        prismlauncher
        android-tools
        obs-studio
        (writeShellApplication {
          name = "scrolllock_keyboard";
          text = ''
            state=$(cat /sys/class/leds/input6::scrolllock/brightness)

            if [ "$state" -eq 1 ]; then
              brightnessctl -d input6::scrolllock set 0
            else
              brightnessctl -d input6::scrolllock set 1
            fi
          '';
        })
      ];

    sessionVariables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
      WLR_DRM_NO_ATOMIC = 1;
      QT_QPA_PLATFORM = "wayland;xcb";
      NIXOS_OZONE_WL = "1";
    };

    file.".face".source = ../../assets/profile.jpg;
  };

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
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
