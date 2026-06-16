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
    ./cloudflare-warp.nix
    ./user.nix
    ./virt-manager.nix
    ./udisk.nix
    ./greetd.nix
    ./polkit.nix
    ./zram.nix
    ./accountservice.nix
    ./pipewire.nix
    ./thermald.nix
  ]
  ++ lib.optionals isDesktop [
    ./opentablet.nix
    ./gamemode.nix
    ./steam.nix
    ./flatpak.nix
  ]
  ++ lib.optionals (!isDesktop) [
    ./nbfc.nix
  ];
}
