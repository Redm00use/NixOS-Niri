{
  lib,
  inputs,
  pkgs,
  unstable,
  mynvim,
  noctalia,
}:
{
  role,
  hostName,
  userName ? "kotlin",
  timeZone ? "Europe/Kyiv",
  defaultLocale ? "ru_RU.UTF-8",
  theme16,
}:
let
  isDesktop = role == "desktop";
  dev = import ../dev {
    inherit
      pkgs
      unstable
      mynvim
      role
      ;
  };

  hostHome = ../hosts/${hostName}/home.nix;
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # Stylix сверяет свой release с release nixpkgs и падает, если они расходятся.
  # Здесь stylix идёт с master, а система — на nixos-25.11, поэтому проверка выключена
  # осознанно. Побочный эффект: после крупного обновления stylix поломка вылезет
  # не сообщением, а странными темами/шрифтами — это первое место, куда стоит смотреть.
  stylix.enableReleaseChecks = false;

  home-manager.extraSpecialArgs = {
    inherit
      inputs
      unstable
      mynvim
      noctalia
      role
      isDesktop
      hostName
      userName
      timeZone
      defaultLocale
      theme16
      ;
  };
  home-manager.users.${userName} = {
    imports = [
      ../modules/home/home.nix
    ]
    ++ lib.optional (builtins.pathExists ../modules/home/profiles/${role}.nix) ../modules/home/profiles/${role}.nix
    ++ lib.optional (builtins.pathExists ../modules/home/profiles/${role}-packages.nix) ../modules/home/profiles/${role}-packages.nix
    ++ [
      inputs.niri-flake.homeModules.niri
      inputs.stylix.homeModules.stylix
      noctalia.homeModules.default
      inputs.dms.homeModules.dank-material-shell
    ]
    ++ lib.optional (builtins.pathExists hostHome) hostHome
    ++ [
      {
        home.packages = dev.extraPackages;
      }
    ];
  };
}
