{
  config,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  font = config.stylix.fonts.monospace;
in
{
  stylix = {
    enable = true;
    polarity = "dark";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark.yaml";

    base16Scheme = {
      base00 = "#222435";
      base01 = "#282a40";
      base02 = "#2d3048";
      base03 = "#7679A7";
      base04 = "#585B89";
      base05 = "#B4B7CF";
      base06 = "#c7c9e0";
      base07 = "#e2be7d";
      base08 = "#E16765";
      base09 = "#EAA041";
      base0A = "#EAE852";
      base0B = "#75BE78";
      base0C = "#46A3AF";
      base0D = "#25ABE4";
      base0E = "#c678dd";
      base0F = "#9a4f7a";
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
      serif = font;
      sansSerif = font;
      emoji = font;
      monospace = {
        name = "FiraCode Nerd Font";
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
