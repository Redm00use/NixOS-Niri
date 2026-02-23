{ ... }:
{
  imports = [
    ../common
    ./hardware-configuration.nix
  ];

  networking.hostName = "gh0stk";
  networking.interfaces.wlo1.mtu = 1450;
}
