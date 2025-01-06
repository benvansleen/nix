{ lib, ... }:

lib.importAll ./.
// {
  config.machine = {
    name = "pi";
    desktop = false;
    powerful = false;
    allowUnfree = true;
  };
}
