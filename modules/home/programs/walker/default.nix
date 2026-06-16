let
  configDir = ../../../../config/walker;
in
{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.walker ];

  home.file.".config/walker/config.toml" = {
    source = configDir + "/config.toml";
    force = true;
  };

  home.file.".config/walker/themes/catppuccin-mocha-apple.css" = {
    source = configDir + "/themes/catppuccin-mocha-apple.css";
    force = true;
  };

  home.file.".config/walker/themes/catppuccin-mocha-apple.toml" = {
    source = configDir + "/themes/catppuccin-mocha-apple.toml";
    force = true;
  };

  home.file.".config/walker/themes/catppuccin-mocha-launchpad.css" = {
    source = configDir + "/themes/catppuccin-mocha-launchpad.css";
    force = true;
  };

  home.file.".config/walker/themes/catppuccin-mocha-launchpad.toml" = {
    source = configDir + "/themes/catppuccin-mocha-launchpad.toml";
    force = true;
  };

  systemd.user.services.walker = {
    Unit = {
      Description = "Walker launcher service";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${lib.getExe pkgs.walker} --gapplication-service";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
