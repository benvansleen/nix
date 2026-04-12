{ lib, ... }:
{
  flake.modules.nixos.unbound = {
    imports = [ ../../modules/system/unbound.nix ];

    config.modules.unbound.enable = lib.mkDefault true;
  };
}
