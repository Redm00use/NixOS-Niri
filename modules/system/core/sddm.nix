{
  config,
  pkgs,
  ...
}:
let
  font = config.stylix.fonts.monospace;
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "hyprland_kath";
    themeConfig = {
      Background = "${../../../assets/wallpapers/wallhaven_rdwjj7.jpg}";
      Font = "${font.name}";
    };
  };
in
{
  services = {
    displayManager = {
      enable = true;
      sddm = {
        enable = true;
        wayland.enable = true;
        package = pkgs.kdePackages.sddm;
        theme = "sddm-astronaut-theme";
        extraPackages = [ sddm-astronaut ];
      };
      defaultSession = "niri";
    };
  };

  environment.systemPackages = [ sddm-astronaut ];
}
