{
  config,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  stylix = {
    enable = true;
    polarity = "dark";

    base16Scheme = {
      base00 = "#1d2021";
      base01 = "#282828";
      base02 = "#3c3836";
      base03 = "#504945";
      base04 = "#bdae93";
      base05 = "#d5c4a1";
      base06 = "#ebdbb2";
      base07 = "#fbf1c7";
      base08 = "#d43847";
      base09 = "#b82c3b";
      base0A = "#e55f4f";
      base0B = "#c32d3a";
      base0C = "#dd434e";
      base0D = "#9f2231";
      base0E = "#c72f44";
      base0F = "#7c1a27";
    };

    targets = {
      gtk.enable = true;
      gtk.flatpakSupport.enable = true;
      qt.enable = true;
      vscode.enable = false;
      cava.enable = false;
      # floorp.profileNames = [
      #   "${config.home.username}"
      # ];
    };

    fonts = {
      serif = config.stylix.fonts.monospace;
      sansSerif = config.stylix.fonts.monospace;
      emoji = config.stylix.fonts.monospace;
      monospace = {
        name = "MonaspiceRn NF";
      };
    };

    cursor = {
      name = "Cursor";
      package = pkgs.callPackage ../../../../pkgs/cursor/package.nix { };
      size = 32;
    };

  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-nord;
    };
    gtk3.bookmarks = [
      "file://${homeDir}/Documents"
      "file://${homeDir}/Downloads"
      "file://${homeDir}/Pictures"
      "file://${homeDir}/Videos"
      "file://${homeDir}/Music"
      "file://${homeDir}/Workspace"
      "file://${homeDir}/nixdots"
    ];
  };

  qt.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  xdg.configFile."gtk-3.0/settings.ini".text = ''
    gtk-application-prefer-dark-theme=true
  '';

  xdg.configFile."gtk-4.0/settings.ini".text = ''
    gtk-application-prefer-dark-theme=true
  '';
}
