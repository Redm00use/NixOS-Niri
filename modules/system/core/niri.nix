{ unstable, pkgs, ... }:
{
  programs.niri = {
    enable = true;
    package = unstable.niri;
    # package = inputs.niri-blurry.packages.${pkgs.system}.niri;
  };
}
