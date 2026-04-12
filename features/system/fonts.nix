{ lib, ... }:
{
  flake.modules.nixos.fonts = {
    imports = [ ../../modules/system/fonts.nix ];

    config.modules.fonts.enable = lib.mkDefault true;
  };
}
