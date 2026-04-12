{ lib, ... }:
{
  flake.modules.nixos.remotebuilder = {
    imports = [ ../../modules/system/remotebuilder.nix ];

    config.modules.remotebuilder.enable = lib.mkDefault true;
  };
}
