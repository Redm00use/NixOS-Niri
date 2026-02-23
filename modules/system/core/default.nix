{
  lib,
  isDesktop ? false,
  ...
}:
{
  imports = [
    ./niri.nix
    ./portals.nix
    ./bluetooth.nix
    ./bootloader.nix
    ./user.nix
    ./virt-manager.nix
    ./udisk.nix
    ./sddm.nix
    ./polkit.nix
    ./zram.nix
    ./accountservice.nix
  ]
  ++ lib.optionals isDesktop [
    ./opentablet.nix
    ./gamemode.nix
    ./flatpak.nix
  ]
  ++ lib.optionals (!isDesktop) [
    ./nbfc.nix
    ./tlp.nix
  ];
}
