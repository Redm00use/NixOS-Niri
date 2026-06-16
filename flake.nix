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

    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs/0741d27d2f7db567270f139c5d1684614ecf9863";
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

      overlay = final: prev: {
        google-chrome-canary = final.callPackage ./pkgs/google-chrome-canary/package.nix { };
        sunder-bin = final.callPackage ./pkgs/sunder-bin/package.nix { };
        portproton = final.callPackage ./pkgs/portproton/package.nix { };
      };

      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };

      theme16 = import ./lib/theme.nix;

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

      sharedHomeManager = import ./lib/mkHome.nix {
        inherit
          lib
          inputs
          pkgs
          unstable
          mynvim
          noctalia
          ;
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
