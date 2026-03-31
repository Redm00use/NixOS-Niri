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

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
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
        base00 = "#1e1e2e";
        base01 = "#181825";
        base02 = "#313244";
        base03 = "#45475a";
        base04 = "#585b70";
        base05 = "#cdd6f4";
        base06 = "#f5e0dc";
        base07 = "#b4befe";
        base08 = "#f38ba8";
        base09 = "#fab387";
        base0A = "#f9e2af";
        base0B = "#a6e3a1";
        base0C = "#94e2d5";
        base0D = "#89b4fa";
        base0E = "#cba6f7";
        base0F = "#f2cdcd";
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
          userName,
          timeZone,
          defaultLocale,
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
                home.packages = dev.extraPackages ++ [ inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default ];
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

      hostEntries = builtins.readDir ./hosts;
      hostNames = lib.filter (
        name:
        hostEntries.${name} == "directory"
        && name != "common"
        && builtins.pathExists ./hosts/${name}/meta.nix
      ) (builtins.attrNames hostEntries);
    in
    {
      nixosConfigurations = lib.genAttrs hostNames mkHost;

      devShells."${system}" =
        let
          desktopShells = (getDev "desktop").devShells;
          serverShells = (getDev "server").devShells;
        in
        desktopShells // serverShells;
    };
}
