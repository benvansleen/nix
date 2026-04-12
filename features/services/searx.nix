{ lib, ... }:
{
  flake.modules.nixos.searx = {
    imports = [ ../../modules/system/searx.nix ];

    config.modules.searx.enable = lib.mkDefault true;
  };
}
