let
  configDir = ../../../../config/niri;
in
{ ... }:
{
  home.file.".config/niri/config.kdl" = {
    source = configDir + "/config.kdl";
    force = true;
  };
}
