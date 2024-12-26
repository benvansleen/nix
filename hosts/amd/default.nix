{ lib, ... }:

lib.importAll ./.
// {
  config.machine = {
    name = "amd";
    powerful = true;
    allowUnfree = true;
  };
}
