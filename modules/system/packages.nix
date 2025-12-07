{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Desktop apps
    telegram-desktop
    obsidian
    kdePackages.ark
    (brave.override {
      commandLineArgs = [
        "--password-store=gnome"
      ];
    })
    gparted

    # CLI utils
    mpv
    exfatprogs
    upower
    tree
    wget
    git
    unzip
    ffmpeg
    zip
    brightnessctl
    nixos-shell
    docker-compose
    qemu
    avahi

    # WM and Wayland stuff
    xwayland-satellite
    wl-clipboard
    cliphist
    zsh
    eza

    # Sound
    pamixer
    pavucontrol

    # Other
    home-manager
    libsForQt5.qtstyleplugins
    libsForQt5.qt5ct
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
    cowsay
    cmatrix
  ];

  # Fonts
  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
  ];
}
