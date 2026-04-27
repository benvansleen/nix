{ inputs, ... }:

{
  flake-file.nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  flake-file.inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-file.url = "github:vic/flake-file";
    systems.url = "github:nix-systems/default";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:nixos/flake-compat";
      flake = false;
    };
    gitignore = {
      url = "github:hercules-ci/gitignore";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
  ];
}
