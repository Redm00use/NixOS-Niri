{ lib, pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    plugins = with pkgs; [
      rofi-calc
      rofi-emoji
      rofi-file-browser
    ];

    terminal = "wezterm";

    extraConfig = {
      modi = "drun,run,filebrowser,emoji,calc";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      display-drun = " Apps";
      display-run = " Run";
      display-filebrowser = " Files";
      display-emoji = " Emoji";
      display-calc = " Calc";
      drun-display-format = "{name}";
      disable-history = false;
      hide-scrollbar = true;
      sidebar-mode = true;
      hover-select = true;
      me-select-entry = "";
      me-accept-entry = "MousePrimary";
      scroll-method = 0;
      window-format = "[{w}] ··· {t}";
      click-to-exit = true;
      max-history-size = 25;
      combi-hide-mode-prefix = true;
      matching = "fuzzy";
      sort = true;
      sorting-method = "fzf";
      normalize-match = true;
      threads = 0;
      case-sensitive = false;
      cycle = true;
      eh = 1;
      auto-select = false;
      parse-hosts = true;
      parse-known-hosts = true;
      tokenize = true;
      m = "-5";
      filter = "";
      config = "";
      no-lazy-grab = false;
      no-plugins = false;
      plugin-path = "/run/current-system/sw/lib/rofi";
      window-thumbnail = false;
      dpi = -1;
    };

    theme = lib.mkForce ./meowrch.rasi;
  };
}
