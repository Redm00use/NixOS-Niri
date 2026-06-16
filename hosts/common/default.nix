# Common host configuration imported by all hosts
# This centralizes shared imports and configuration
{ ... }:
{
  imports = [
    ../../modules/system/configuration.nix
  ];
}

