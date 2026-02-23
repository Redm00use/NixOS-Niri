# Helper function to create a NixOS host configuration
# This encapsulates the common host creation logic
{
  nixpkgs,
  home-manager,
  inputs,
  nur,
  sharedHomeManager,
  unstable,
}:
name:
let
  metaPath = ../hosts/${name}/meta.nix;
  meta = if builtins.pathExists metaPath then import metaPath else { };
  role = meta.role or "desktop";
  isDesktop = meta.isDesktop or (role == "desktop");
  hostName = meta.hostName or name;
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
      ;
  };
  modules = [
    ../hosts/${name}
    nur.modules.nixos.default
    inputs.stylix.nixosModules.stylix
    inputs.nix-flatpak.nixosModules.nix-flatpak
    home-manager.nixosModules.home-manager
    (sharedHomeManager {
      inherit role hostName;
    })
  ];
}
