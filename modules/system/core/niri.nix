{
  unstable,
  pkgs,
  ...
}:
{
  programs.niri = {
    enable = true;
    package = unstable.niri;
  };
}
