{ nixos-facter-modules, pkgs, ... }:

{
  imports = [
    nixos-facter-modules.nixosModules.facter
  ];

  config = {
    facter.reportPath = ./facter.json;

    hardware = {
      cpu.ryzen-smu.enable = true;
      graphics.extraPackages = with pkgs; [
        amdvlk
      ];
    };
  };
}
