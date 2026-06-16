{
  pkgs,
  unstable,
  lib,
  role ? "desktop",
  ...
}:
let
  isDesktop = role == "desktop";
in
{
  environment.systemPackages =
    with pkgs;
    [
      codex
      telegram-desktop
      kdePackages.ark
      gparted
      mpv
      yt-dlp
      freerdp
      exfatprogs
      upower
      tree
      wget
      git
      unzip
      unrar
      ffmpeg
      zip
      brightnessctl
      playerctl
      nixos-shell
      qemu
      avahi
      grim
      slurp
      xwayland-satellite
      wl-clipboard
      wtype
      cliphist
      eww
      zsh
      eza
      pamixer
      pavucontrol
      home-manager
      unstable.libsForQt5.qtstyleplugins
      unstable.libsForQt5.qt5ct
      unstable.kdePackages.qt6ct
      unstable.kdePackages.qtmultimedia
      unstable.kdePackages.qtstyleplugin-kvantum
    ]
    ++ lib.optionals isDesktop [
      obsidian
      cowsay
      cmatrix
      nbfc-linux
    ];

  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
