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

    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark.yaml";

    # base16Scheme = {
    #   base00 = "#222435";
    #   base01 = "#282a40";
    #   base02 = "#2d3048";
    #   base03 = "#7679A7";
    #   base04 = "#585B89";
    #   base05 = "#B4B7CF";
    #   base06 = "#c7c9e0";
    #   base07 = "#e2be7d";
    #   base08 = "#E16765";
    #   base09 = "#EAA041";
    #   base0A = "#EAE852";
    #   base0B = "#75BE78";
    #   base0C = "#46A3AF";
    #   base0D = "#25ABE4";
    #   base0E = "#c678dd";
    #   base0F = "#9a4f7a";
    # };

    # base16Scheme = {
    #   base00 = "#1d2021";
    #   base01 = "#282828";
    #   base02 = "#3c3836";
    #   base03 = "#504945";
    #   base04 = "#bdae93";
    #   base05 = "#d5c4a1";
    #   base06 = "#ebdbb2";
    #   base07 = "#fbf1c7";
    #   base08 = "#d43847";
    #   base09 = "#b82c3b";
    #   base0A = "#e55f4f";
    #   base0B = "#c32d3a";
    #   base0C = "#dd434e";
    #   base0D = "#9f2231";
    #   base0E = "#c72f44";
    #   base0F = "#7c1a27";
    # };

    targets = {
      gtk.enable = true;
      gtk.flatpakSupport.enable = true;
      qt.enable = true;
      vscode.enable = false;
      cava.enable = false;
      noctalia-shell.enable = false;
      starship.enable = false;
      dank-material-shell.enable = true;
    };

    fonts = {
      serif = font;
      sansSerif = font;
      emoji = font;
      monospace = {
        name = "VictorMono NF";
      };
    };

    cursor = {
      name = "catppuccin-mocha-mauve-cursors";
      package = pkgs.catppuccin-cursors.mochaMauve;
      size = 32;
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
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

  # dconf.settings = {
  #   "org/gnome/desktop/interface" = {
  #     color-scheme = "prefer-dark";
  #   };
  # };
  #
  # xdg.configFile."gtk-3.0/settings.ini".text = ''
  #   gtk-application-prefer-dark-theme=true
  # '';
  #
  # xdg.configFile."gtk-4.0/settings.ini".text = ''
  #   gtk-application-prefer-dark-theme=true
  # '';
}
