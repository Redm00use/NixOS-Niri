{ ... }:
{
  imports = [
    ../common
    ./hardware-configuration.nix
  ];

  networking.hostName = "slime";
}
