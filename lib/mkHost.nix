# Helper function to create a NixOS host configuration
# This encapsulates the common host creation logic
{
  nixpkgs,
  home-manager,
  inputs,
  nur,
  mynvim,
  noctalia,
  theme16,
  pkgsFor,
  unstableFor,
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

  # Пароль первого входа. Переопределяется в hosts/<host>/meta.nix.
  # После первой загрузки его нужно сменить через passwd.
  initialPassword = meta.initialPassword or "nixos";

  # Архитектура больше не зашита в flake: хост может быть и aarch64.
  system = meta.system or "x86_64-linux";

  pkgs = pkgsFor system;
  unstable = unstableFor system;

  sharedHomeManager = import ./mkHome.nix {
    lib = nixpkgs.lib;
    inherit
      inputs
      pkgs
      unstable
      mynvim
      noctalia
      ;
  };
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
      initialPassword
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
