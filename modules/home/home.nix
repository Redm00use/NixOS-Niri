{
  config,
  pkgs,
  unstable,
  ...
}:
{
  imports = [
    ./programs
  ];

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "vitor";
    homeDirectory = "/home/vitor";
    stateVersion = "25.05";
    packages = with pkgs; [
      gnome.gvfs
      nautilus
      bc
      imagemagick
      unstable.pokemon-colorscripts
      unstable.gowall
      qimgv
      prismlauncher
      librewolf
      usbutils
      usbredir

      # Bootloader
      android-tools
      obs-studio
    ];

    sessionVariables = {
      TERMINAL = "wezterm";
      EDITOR = "nvim";
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
