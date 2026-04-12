{ lib, ... }:
{
  flake.modules.nixos.btrfs = {
    imports = [ ../../modules/system/btrfs.nix ];

    config.modules.btrfs.enable = lib.mkDefault true;
  };
}
