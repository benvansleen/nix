{ nixos-facter-modules, ... }:

{
  imports = [
    nixos-facter-modules.nixosModules.facter
  ];

  config.facter.reportPath = ./facter.json;
}
