{ pkgs, ... }:
{
  services.xserver = {
    enable = true;

    xkb = {
      layout = "us,ru";
      variant = "";
      options = "grp:caps_toggle";
    };

    excludePackages = [ pkgs.xterm ];

    deviceSection = ''
      Option "AccelMethod" "none"
    '';
  };
}
