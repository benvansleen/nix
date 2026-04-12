{ lib, ... }:
{
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.homeManager = {
    imports = [ ../../modules/system/home-manager.nix ];

    config.modules.home-manager.enable = lib.mkDefault true;
  };
}
