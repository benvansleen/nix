{ lib, ... }:

lib.importAll ./.
// {
  config.machine = {
    name = "desktop";
    desktop = true;
    powerful = true;
    allowUnfree = true;
  };
}
