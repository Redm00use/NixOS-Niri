{ hostName ? "generated", ... }:
{
  imports = [
    ../common
    ./hardware-configuration.nix
  ];

  networking.hostName = hostName;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
