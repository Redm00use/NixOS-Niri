{
  imports = [
    ../../drivers
  ];

  drivers.amdgpu.enable = false;
  drivers.nvidia.enable = false;
  drivers.intel.enable = false;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
}
