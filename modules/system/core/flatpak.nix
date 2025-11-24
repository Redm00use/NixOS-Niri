{ pkgs, ... }:
{
  services.flatpak = {
    enable = true;
    packages = [
      # {
      #   appId = "com.usebottles.bottles";
      #   origin = "flathub";
      # }
      {
        appId = "";
        origin = "flathub";
      }
    ];
  };
}
