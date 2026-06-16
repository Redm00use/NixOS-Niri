{ pkgs, ... }:
let
  managedDevices = [
    "68:FE:F7:62:E8:2A"
    "1C:1A:C0:F2:53:BE"
    "40:B3:FA:06:E9:DB"
  ];
  deviceList = builtins.concatStringsSep " " managedDevices;

  bluetoothDeviceReconnect = pkgs.writeShellScriptBin "bluetooth-device-reconnect" ''
    set -eu

    mac="''${1:?missing bluetooth mac}"
    tries=99999999
    delay=2

    ${pkgs.bluez}/bin/bluetoothctl power on >/dev/null 2>&1 || true
    ${pkgs.bluez}/bin/bluetoothctl agent on >/dev/null 2>&1 || true
    ${pkgs.bluez}/bin/bluetoothctl default-agent >/dev/null 2>&1 || true
    ${pkgs.bluez}/bin/bluetoothctl trust "$mac" >/dev/null 2>&1 || true

    attempt=1
    while [ "$attempt" -le "$tries" ]; do
      if ${pkgs.bluez}/bin/bluetoothctl info "$mac" | ${pkgs.gnugrep}/bin/grep -q "Connected: yes"; then
        echo "Bluetooth device $mac already connected on attempt $attempt"
        exit 0
      fi

      echo "Bluetooth device $mac reconnect attempt $attempt/$tries"
      ${pkgs.bluez}/bin/bluetoothctl connect "$mac" >/dev/null 2>&1 || true
      sleep "$delay"

      if ${pkgs.bluez}/bin/bluetoothctl info "$mac" | ${pkgs.gnugrep}/bin/grep -q "Connected: yes"; then
        echo "Bluetooth device $mac connected on attempt $attempt"
        exit 0
      fi

      attempt=$((attempt + 1))
    done

    echo "Failed to connect bluetooth device $mac after $tries attempts"
    exit 1
  '';

  bluetoothDevicesWatch = pkgs.writeShellScriptBin "bluetooth-devices-watch" ''
    set -eu

    while true; do
      for mac in ${deviceList}; do
        if ! ${bluetoothDeviceReconnect}/bin/bluetooth-device-reconnect "$mac"; then
          echo "Reconnect cycle failed for $mac"
        fi
      done

      sleep 2
    done
  '';
in
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  services.blueman.enable = true;

  environment.systemPackages = [
    bluetoothDeviceReconnect
    bluetoothDevicesWatch
  ];

  systemd.services.bluetooth-keyboard-reconnect = {
    description = "Reconnect managed Bluetooth devices with retries";
    after = [
      "bluetooth.service"
      "multi-user.target"
    ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${bluetoothDeviceReconnect}/bin/bluetooth-device-reconnect ${builtins.head managedDevices}";
      RemainAfterExit = false;
    };
  };

  systemd.services.bluetooth-keyboard-watch = {
    description = "Keep managed Bluetooth devices connected";
    after = [
      "bluetooth.service"
      "multi-user.target"
    ];
    wants = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${bluetoothDevicesWatch}/bin/bluetooth-devices-watch";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
