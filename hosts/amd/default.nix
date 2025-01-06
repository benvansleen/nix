{ lib, ... }:

lib.importAll ./.
// {
  config.machine = {
    name = "amd";
    desktop = true;
    powerful = true;
    allowUnfree = true;
  };
}
