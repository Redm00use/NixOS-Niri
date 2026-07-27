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

  # resume включается только без LUKS.
  # Инсталлер создаёт swap отдельным НЕЗАШИФРОВАННЫМ разделом, а образ гибернации —
  # это слепок памяти целиком, включая ключи шифрования root.
  # Включать resume в такой конфигурации — значит сводить шифрование на нет.
  boot.resumeDevice = lib.mkIf (swapUuid != null && !luksEnabled) "/dev/disk/by-uuid/${swapUuid}";

  services.fstrim.enable = true;
}
