{
  pkgs,
  userName ? "kotlin",
  # Пароль первого входа. Задаётся через hosts/<host>/meta.nix (initialPassword).
  # ВАЖНО: это публичное значение из гита, смени его сразу после установки: passwd
  initialPassword ? "nixos",
  ...
}:
{
  programs.zsh.enable = true;

  users = {
    defaultUserShell = pkgs.zsh;

    users.${userName} = {
      isNormalUser = true;
      group = userName;
      description = userName;
      inherit initialPassword;
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
