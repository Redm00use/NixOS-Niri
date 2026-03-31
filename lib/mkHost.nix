# Helper function to create a NixOS host configuration
# This encapsulates the common host creation logic
{
  nixpkgs,
  home-manager,
  inputs,
  nur,
  sharedHomeManager,
  unstable,
  theme16,
}:
name:
let
  metaPath = ../hosts/${name}/meta.nix;
  meta = if builtins.pathExists metaPath then import metaPath else { };
  role = meta.role or "desktop";
  isDesktop = meta.isDesktop or (role == "desktop");
  hostName = meta.hostName or name;
  userName = meta.userName or "kotlin";
  gpuType = meta.gpuType or "amd";
  timeZone = meta.timeZone or "Europe/Kyiv";
  defaultLocale = meta.defaultLocale or "ru_RU.UTF-8";
  separateHome = meta.separateHome or false;
  homeSizeGiB = meta.homeSizeGiB or 0;
  swapSizeGiB = meta.swapSizeGiB or 0;
  luksEnabled = meta.luksEnabled or false;
  rootFs = meta.rootFs or "btrfs";
  luksPartUuid = meta.luksPartUuid or null;
  swapUuid = meta.swapUuid or null;
  system = "x86_64-linux";
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit
      inputs
      unstable
      role
      isDesktop
      hostName
      userName
      gpuType
      timeZone
      defaultLocale
      separateHome
      homeSizeGiB
      swapSizeGiB
      luksEnabled
      rootFs
      luksPartUuid
      swapUuid
      theme16
      ;
  };
  modules = [
    ../hosts/${name}
    nur.modules.nixos.default
    inputs.stylix.nixosModules.stylix
    inputs.nix-flatpak.nixosModules.nix-flatpak
    home-manager.nixosModules.home-manager
    (sharedHomeManager {
      inherit role hostName userName timeZone defaultLocale theme16;
    })
  ];
}
