{ lib, ... }:
{
  flake-file.inputs.impermanence = {
    url = "github:nix-community/impermanence";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
    };
  };

  flake.modules.nixos.impermanence = {
    imports = [ ../../modules/system/impermanence.nix ];

    config.modules.impermanence.enable = lib.mkDefault true;
  };

  flake.modules.homeManager.impermanence = {
    imports = [ ../../modules/home/impermanence.nix ];
  };
}
