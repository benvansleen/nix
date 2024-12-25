{ ... }:

{
  imports = [
    ./system.nix
  ];

  config.machine = {
    name = "amd";
    powerful = true;
    allowUnfree = true;
  };
}
