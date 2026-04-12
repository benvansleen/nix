{ lib, ... }:
{
  flake.modules.nixos.crossplatformBuilder = {
    imports = [ ../../modules/system/crossplatform-builder.nix ];

    config.modules.crossplatform-builder.enable = lib.mkDefault true;
  };
}
