{ inputs, lib, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
    };
  };

  flake.modules.nixos.stylix = {
    imports = [ ../../modules/system/stylix.nix ];

    config.modules.stylix.enable = lib.mkDefault true;
  };

  flake.modules.homeManager.stylix = {
    imports = [
      (
        inputs.stylix.homeModules.stylix
        or inputs.stylix.homeModules.default
        or inputs.stylix.homeManagerModules.stylix
        or inputs.stylix.homeManagerModules.default
      )
    ];
  };
}
