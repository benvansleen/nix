{ ... }:

{
  imports = [
    ./system.nix
  ];

  config.machine = {
    name = "qemu";
    powerful = false;
  };
}
