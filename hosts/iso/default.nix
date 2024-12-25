{ ... }:

{
  imports = [
    ./system.nix
  ];

  config.machine = {
    name = "iso";
    powerful = false;
  };
}
