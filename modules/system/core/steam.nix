{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamescope.enable = true;

  environment.systemPackages = with pkgs; [
    heroic
    lutris
    protonup-qt
    mangohud
  ];
}
