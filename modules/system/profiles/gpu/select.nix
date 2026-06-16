{ gpuType ? "amd", ... }:
{
  imports = [ ./${gpuType}.nix ];
}
