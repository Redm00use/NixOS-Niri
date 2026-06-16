{ pkgs, ... }:

{
  home.packages = [
    (pkgs.symlinkJoin {
      name = "mailspring-wrapped";
      paths = [ pkgs.mailspring ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        rm -f $out/bin/mailspring
        makeWrapper ${pkgs.mailspring}/bin/mailspring $out/bin/mailspring \
          --add-flags "--password-store=gnome-libsecret"
      '';
    })
  ];

  xdg.desktopEntries."mailspring" = {
    name = "Mailspring";
    exec = "mailspring --password-store=gnome-libsecret %U";
    icon = "mailspring";
    terminal = false;
    categories = [ "Office" "Email" "Network" ];
    mimeType = [ "x-scheme-handler/mailto" ];
  };
}
