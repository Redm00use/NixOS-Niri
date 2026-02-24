{
  pkgs,
  unstable,
  config,
  ...
}:
{
  programs.dank-material-shell = {
    enable = false;
    quickshell.package = unstable.quickshell;
    enableSystemMonitoring = true;
    enableDynamicTheming = false;
    dgop.package = unstable.dgop;
    # managePluginSettings = true;
    # plugins = {
    #   dankPomodoroTimer = {
    #     enable = true;
    #   };
    #   dankKDEConnect = {
    #     enable = true;
    #   };
    # };
  };
}
