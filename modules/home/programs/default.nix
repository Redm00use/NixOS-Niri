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
    ./rofi
    ./stylix
    ./noctalia
    ./wezterm
    ./direnv
    ./yazi
    ./btop
    ./shell
    # ./starship
  ]
  ++ lib.optionals isDesktop [
    ./fastfetch
    ./cava
    ./lazygit
  ];
}
