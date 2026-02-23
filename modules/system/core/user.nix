{ config, pkgs, ... }:
{
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;

    users.vitor = {
      isNormalUser = true;
      group = "vitor";
      description = "Vitor";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "kvm"
        "libvirtd"
        "plugdev"
        "video"
        "input"
      ];
      ignoreShellProgramCheck = true;
    };

    groups.vitor = {};
  };
}
