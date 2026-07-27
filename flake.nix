{
  description = "Kotlin NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    mynvim.url = "github:viitorags/nvim";

    stylix.url = "github:nix-community/stylix";

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";

    niri-blur.url = "github:YaLTeR/niri?ref=wip/branch";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Версия закреплена в flake.lock, а не в URL: иначе `nix flake update`
    # молча не работает и вход вечно висит на старом коммите.
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # noctalia / noctalia-qs / dms / quickshell — один QML-стек.
    # Держим их на одном дереве nixpkgs (unstable), иначе плагины
    # собираются против разных версий Qt и ломаются в runtime.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixpkgs-unstable,
      mynvim,
      noctalia,
      nur,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      # Системы, для которых экспортируются devShells.
      # Архитектура хоста берётся из meta.system, а не из глобальной константы.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs systems;

      overlay = final: prev: {
        google-chrome-canary = final.callPackage ./pkgs/google-chrome-canary/package.nix { };
        sunder-bin = final.callPackage ./pkgs/sunder-bin/package.nix { };
        portproton = final.callPackage ./pkgs/portproton/package.nix { };
      };

      mkPkgs =
        source: system:
        import source {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        };

      pkgsFor = mkPkgs nixpkgs;
      unstableFor = mkPkgs nixpkgs-unstable;

      theme16 = import ./lib/theme.nix;

      getDev =
        system: role:
        import ./dev {
          pkgs = pkgsFor system;
          unstable = unstableFor system;
          inherit mynvim role;
        };

      mkHost = import ./lib/mkHost.nix {
        inherit
          nixpkgs
          home-manager
          inputs
          nur
          mynvim
          noctalia
          theme16
          pkgsFor
          unstableFor
          ;
      };

      hostEntries = builtins.readDir ./hosts;

      # hosts/common — общие модули, hosts/generated — шаблон для инсталлера.
      # Ни то, ни другое не должно становиться собираемым хостом.
      ignoredHosts = [
        "common"
        "generated"
      ];

      hostNames = lib.filter (
        name:
        hostEntries.${name} == "directory"
        && !(lib.elem name ignoredHosts)
        && !(lib.hasInfix ".backup-" name)
        && builtins.pathExists ./hosts/${name}/meta.nix
      ) (builtins.attrNames hostEntries);
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      devShells = forAllSystems (
        system:
        let
          desktopShells = (getDev system "desktop").devShells;
          serverShells = (getDev system "server").devShells;
        in
        desktopShells // serverShells
      );
    };
}
