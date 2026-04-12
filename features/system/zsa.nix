{ lib, ... }:
{
  flake.modules.nixos.zsa = {
    imports = [ ../../modules/system/zsa.nix ];

    config.modules.zsa.enable = lib.mkDefault true;
  };
}
