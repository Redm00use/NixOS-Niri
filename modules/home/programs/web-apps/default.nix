{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg =
    let
      browser = lib.getExe pkgs.brave;
      homeDir = config.home.homeDirectory;
    in
    {
      desktopEntries = {
        discord = {
          name = "Discord";
          exec = "${browser} --password-store=gnome --app=https://discord.com/app";
          icon = "${homeDir}/nixdots/assets/icons/discord.png";
          terminal = false;
          categories = [
            "Network"
            "InstantMessaging"
          ];
        };

        trello = {
          name = "Trello";
          exec = "${browser} --password-store=gnome --app=https://trello.com/";
          icon = "${homeDir}/nixdots/assets/icons/trello.png";
          terminal = false;
          # categories = [];
        };

        youtube = {
          name = "Youtube";
          exec = "${browser} --password-store=gnome --app=https://youtube.com/";
          icon = "${homeDir}/nixdots/assets/icons/youtube.png";
          terminal = false;
          # categories = [];
        };

        youtube-music = {
          name = "Youtube Music";
          exec = "${browser} --password-store=gnome --app=https://music.youtube.com/";
          icon = "${homeDir}/nixdots/assets/icons/youtube-music.png";
          terminal = false;
          # categories = [];
        };

        google-tradutor = {
          name = "Google Tradutor";
          exec = "${browser} --password-store=gnome --app=https://translate.google.com.br/";
          icon = "${homeDir}/nixdots/assets/icons/google-translate.png";
          terminal = false;
          # categories = [];
        };
      };
    };
}
