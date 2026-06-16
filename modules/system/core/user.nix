{ pkgs, userName ? "kotlin", ... }:
{
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;

    users.${userName} = {
      isNormalUser = true;
      group = userName;
      description = userName;
      initialPassword = "1408";
      extraGroups = [
        "networkmanager"
        "wheel"
        "kvm"
        "libvirtd"
        "plugdev"
        "video"
        "input"
      ];
      ignoreShellProgramCheck = true;
    };

    groups.${userName} = {};
  };
}
