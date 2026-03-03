{
  lib,
  role ? "desktop",
  ...
}:
let
  isDesktop = role == "desktop";
in
{
  imports = [
    ./niri
    ./stylix
    ./noctalia
    ./wezterm
    ./direnv
    ./yazi
    ./btop
    ./shell
    # ./starship
    ./sioyek
  ]
  ++ lib.optionals isDesktop [
    ./fastfetch
    ./cava
    ./lazygit
    ./vesktop
  ];
}
