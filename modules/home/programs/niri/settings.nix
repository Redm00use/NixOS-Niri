{ pkgs, config, ... }:
{
  programs.niri = with config.lib.stylix.colors; {
    enable = true;
    settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "br";
          };

          numlock = true;
        };

        touchpad = {
          tap = true;
          natural-scroll = true;
        };

        mouse = {
          enable = true;
        };

        trackpoint = {
          enable = true;
        };
      };

      layout = {
        gaps = 8;

        center-focused-column = "never";

        preset-column-widths = [
          {
            "proportion" = 0.33333;
          }
          { "proportion" = 0.5; }
          { "proportion" = 0.66667; }
        ];

        default-column-width = {
          proportion = 0.5;
        };

        focus-ring = {
          enable = false;
        };

        border = {
          enable = true;
          width = 2;
          active.color = "#${base0E}";
          inactive.color = "#505050";
          urgent.color = "#9b0000";
        };

        shadow = {
          enable = false;

          softness = 30;

          spread = 5;

          offset = "x=0 y=5";

          color = "#0007";
        };

        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
      };

      hotkey-overlay = {
        skip-at-startup = true;
      };

      environment = {
        SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_DESKTOP = "niri";
        QT_QPA_PLATFORMTHEME = "qt5ct";
        DISPLAY = ":0";
        QS_ICON_THEME = "Papirus-Dark";
      };

      spawn-at-startup = [
        { command = [ "${pkgs.polkit_gnome}/bin/polkit-gnome-authentication-agent-1" ]; }
        { command = [ "noctalia-shell" ]; }
        { command = [ "xwayland-satellite" ]; }
        { command = [ "wl-paste --type text --watch cliphist store" ]; }
        { command = [ "wl-paste --type image --watch cliphist store" ]; }
      ];

      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      animations = {
        slowdown = 2.0;
      };

      overview = {
        zoom = 0.5;
      };

      gestures = {
        hot-corners = {
          enable = false;
        };
      };
    };
  };
}
