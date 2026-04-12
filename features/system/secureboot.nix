{ lib, ... }:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      pre-commit.inputs.flake-compat.follows = "flake-compat";
    };
  };

  flake.modules.nixos.secureboot = {
    imports = [ ../../modules/system/secureboot.nix ];

    config.modules.secureboot.enable = lib.mkDefault true;
  };
}
