{ lib, ... }:

lib.importAll ./.
// {
  config.machine = {
    name = "laptop";
    desktop = true;
    powerful = false;
    allowUnfree = true;
  };
}
