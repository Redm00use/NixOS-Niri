{
  lib,
  luksEnabled ? false,
  luksPartUuid ? null,
  swapUuid ? null,
  ...
}:
{
  boot.initrd.systemd.enable = lib.mkIf luksEnabled true;

  boot.initrd.luks.devices = lib.mkIf (luksEnabled && luksPartUuid != null) {
    cryptroot = {
      device = "/dev/disk/by-partuuid/${luksPartUuid}";
      allowDiscards = true;
    };
  };

  boot.resumeDevice = lib.mkIf (swapUuid != null) "/dev/disk/by-uuid/${swapUuid}";

  services.fstrim.enable = true;
}
