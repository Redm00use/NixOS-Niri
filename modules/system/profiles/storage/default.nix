{
  lib,
  luksEnabled ? false,
  lvmEnabled ? false,
  luksPartUuid ? null,
  swapUuid ? null,
  ...
}:
{
  boot.initrd.services.lvm.enable = lib.mkIf lvmEnabled true;

  boot.initrd.systemd.enable = lib.mkIf luksEnabled true;

  boot.initrd.luks.devices = lib.mkIf (luksEnabled && luksPartUuid != null) {
    cryptroot = {
      device = lib.mkDefault "/dev/disk/by-partuuid/${luksPartUuid}";
      allowDiscards = true;
    };
  };

  # Автоматический resume отключён при любом LUKS.
  # Без LVM swap не шифруется. Для LVM-over-LUKS восстановление
  # из гибернации с разблокировкой здесь отдельно не настраивается.
  boot.resumeDevice = lib.mkIf (swapUuid != null && !luksEnabled) "/dev/disk/by-uuid/${swapUuid}";

  services.fstrim.enable = true;
}
