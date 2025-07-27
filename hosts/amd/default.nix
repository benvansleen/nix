{ lib, ... }:

lib.importAll ./.
// {
  config.machine = {
    name = "amd";
    desktop = true;
    powerful = true;
    allowUnfree = true;
    acceleration = "rocm";
    rocm-version = "11.0.0";
  };
}
