{ lib, ... }:
{
  flake-file.inputs.nixos-cli = {
    url = "github:nix-community/nixos-cli";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
      optnix.inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
  };

  flake.modules.nixos.nixosCli = {
    imports = [ ../../modules/system/nixos-cli.nix ];

    config.modules.nixos-cli.enable = lib.mkDefault true;
  };
}
