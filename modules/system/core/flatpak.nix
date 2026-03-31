{ pkgs, ... }:
{
  services.flatpak = {
    enable = true;
    packages = [
      {
        appId = "app.ytmdesktop.ytmdesktop";
        origin = "flathub";
      }
      # {
      #   appId = "com.usebottles.bottles";
      #   origin = "flathub";
      # }
    ];
  };
}
