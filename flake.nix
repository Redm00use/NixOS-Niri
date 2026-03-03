{
  description = "Viitorags NixOs Configuration";

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

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
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
      system = "x86_64-linux";

      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      theme16 = {
        base00 = "#1d2021";
        base01 = "#282828";
        base02 = "#3c3836";
        base03 = "#504945";
        base04 = "#bdae93";
        base05 = "#d5c4a1";
        base06 = "#ebdbb2";
        base07 = "#fbf1c7";
        base08 = "#d43847";
        base09 = "#b82c3b";
        base0A = "#e55f4f";
        base0B = "#c32d3a";
        base0C = "#dd434e";
        base0D = "#9f2231";
        base0E = "#c72f44";
        base0F = "#7c1a27";
      };

      getDev =
        role:
        import ./dev {
          inherit
            pkgs
            unstable
            mynvim
            role
            ;
        };

      sharedHomeManager =
        {
          role,
          hostName,
          theme16,
        }:
        let
          isDesktop = role == "desktop";
          dev = import ./dev {
            inherit
              pkgs
              unstable
              mynvim
              role
              ;
          };

          hostHome = ./hosts/${hostName}/home.nix;
        in
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit
              inputs
              unstable
              mynvim
              noctalia
              role
              isDesktop
              hostName
              theme16
              ;
          };
          home-manager.users.vitor = {
            imports = [
              ./modules/home/home.nix
            ]
            ++ lib.optional (builtins.pathExists ./modules/home/profiles/${role}.nix) ./modules/home/profiles/${role}.nix
            ++ lib.optional (builtins.pathExists ./modules/home/profiles/${role}-packages.nix) ./modules/home/profiles/${role}-packages.nix
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
        };

      mkHost = import ./lib/mkHost.nix {
        inherit
          nixpkgs
          home-manager
          inputs
          nur
          unstable
          sharedHomeManager
          theme16
          ;
      };
    in
    {
      nixosConfigurations = {
        gh0stk = mkHost "gh0stk";
        slime = mkHost "slime";
      };

      devShells."${system}" =
        let
          desktopShells = (getDev "desktop").devShells;
          serverShells = (getDev "server").devShells;
        in
        desktopShells // serverShells;
    };
}
