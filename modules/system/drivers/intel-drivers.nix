{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.drivers.intel;
in
{
  options.drivers.intel = {
    enable = mkEnableOption "Enable Intel Graphics Drivers";
  };

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = [ "intel" ];
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        libvdpau-va-gl
        intel-media-driver
        intel-vaapi-driver
        mesa
        libglvnd
        vulkan-loader
        libva
      ];
    };

    environment.variables = {
      LIBVA_DRIVER_NAME = "iHD";
      VDPAU_DRIVER = "va_gl";
    };
  };
}
