{ unstable, ... }:
{
  imports = [
    ./binds.nix
    ./settings.nix
    ./rules.nix
  ];
  programs.niri = {
    enable = true;
    package = unstable.niri;
  };
}
