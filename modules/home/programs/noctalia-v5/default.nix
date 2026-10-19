{ config, inputs, pkgs, lib, ... }:
let
  homeDir = config.home.homeDirectory;
  pluginDir = "${config.xdg.dataHome}/noctalia-v5-plugins";
in
{
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = builtins.replaceStrings
      [ "@PLUGIN_DIR@" "@WALLPAPER_DIR@" ]
      [ pluginDir "${../../../../assets/wallpapers}" ]
      (builtins.readFile ./config.toml);
    customPalettes.Original = ./Original.json;
  };

  xdg.dataFile."noctalia-v5-plugins".source = ./plugins;

  home.activation.noctaliaApplicationNames = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${pkgs.python3}/bin/python3 ${./app-names.py} \
      ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/apps.json"} \
      ${lib.escapeShellArg homeDir} ${lib.escapeShellArg config.home.username}
    touch ${lib.escapeShellArg "${config.xdg.stateHome}/noctalia/.setup-complete"}
  '';
}
