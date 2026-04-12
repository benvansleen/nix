{ lib, ... }:
{
  flake-file.inputs.extra-container = {
    url = "github:erikarvstedt/extra-container";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.containers = {
    imports = [ ../../modules/system/containers.nix ];

    config.modules.containers.enable = lib.mkDefault true;
  };
}
