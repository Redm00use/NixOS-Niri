{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Zed Editor — clean public config (add your own API keys and preferences)
  xdg.configFile."zed/settings.json" = {
    force = true;
    text = builtins.toJSON {
      icon_theme = "Zed (Default)";
      ui_font_size = 16;
      buffer_font_size = 15;
      theme = {
        mode = "dark";
        light = "One Light";
        dark = "One Dark";
      };
    };
  };
}
