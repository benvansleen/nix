{ lib, ... }:
{
  flake.modules.nixos.displayManager = {
    imports = [ ../../modules/system/display-manager ];

    config.modules.display-manager.enable = lib.mkDefault true;
  };
}
