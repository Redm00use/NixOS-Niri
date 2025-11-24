{
  pkgs,
  unstable,
  config,
  ...
}:
let
  username = config.home.username;
  homeDir = config.home.homeDirectory;
in
{
  programs.floorp = {
    enable = true;

    package = unstable.floorp-bin;

    profiles = {
      ${username} = {
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            bitwarden
            darkreader
          ];
        };

        settings = {
          "floorp.browser.ssb.enabled" = true;
          "floorp.panelSidebar.enabled" = false;
          "sidebar.verticalTabs" = true;
          "sidebar.expandOnHover" = true;
          "sidebar.position_start" = false;
          "sidebar.visibility" = "expand-on-hover";
          "floorp.browser.user.interface" = 8;
        };
      };
    };

    policies = {
      ExtensionSettings = {
        # TWP - Translate Web Pages
        "{036a55b4-5e72-4d05-a06c-cba2dfcc134a}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4455681/traduzir_paginas_web-10.1.1.1.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
}
