{
  config,
  pkgs,
  lib,
  role ? "desktop",
  timeZone ? "Europe/Kyiv",
  defaultLocale ? "ru_RU.UTF-8",
  swapSizeGiB ? 0,
  ...
}:
{
  imports = [
    ./packages.nix
    ./core
    ./profiles/gpu/select.nix
    ./profiles/storage
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;

  nix.settings = {
    substituters = [
      "https://viitorags.cachix.org"
    ];

    trusted-public-keys = [
      "viitorags.cachix.org-1:XjszObjD+IWSHIB37cprlJogQkkKgWLtcBRH7pi/gpE="
    ];

    fallback = false;
  };

  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.networkmanager.enable = true;
  networking.nameservers = [
    "1.1.1.2"
    "8.8.8.8"
  ];

  time.timeZone = timeZone;

  i18n.defaultLocale = defaultLocale;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "uk_UA.UTF-8";
    LC_IDENTIFICATION = "uk_UA.UTF-8";
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_MONETARY = "uk_UA.UTF-8";
    LC_NAME = "uk_UA.UTF-8";
    LC_NUMERIC = "uk_UA.UTF-8";
    LC_PAPER = "uk_UA.UTF-8";
    LC_TELEPHONE = "uk_UA.UTF-8";
    LC_TIME = "uk_UA.UTF-8";
  };

  console.keyMap = "ru";
  swapDevices = lib.mkIf (swapSizeGiB == 0) [ ];
  nixpkgs.config.allowUnfree = true;
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      epson-escpr
    ];
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*::scrolllock", RUN+="/bin/sh -c 'chmod 666 /sys/class/leds/%k/brightness /sys/class/leds/%k/trigger'"
  '';

  system.stateVersion = "25.11";
}
