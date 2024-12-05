{
  description = "NixOS config";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      pre-commit-hooks,
      treefmt-nix,
      ...
    }@inputs:
    let
      utils = import ./utils.nix inputs;
      overlays = import ./overlays inputs;

      treefmtEval = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

      defaultSystem = utils.makeSystem overlays nixpkgs;
    in
    rec {
      nixosConfigurations = {
        qemu = defaultSystem "x86_64-linux" [ ./hosts/qemu ];
        iso = defaultSystem "x86_64-linux" [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./hosts/iso
        ];
      };

      # homeConfigurations = {
      #   "ben@qemu" = nixosConfigurations.qemu.config.home-manager.users.ben.home;
      # };

      formatter = utils.eachSystem ({ pkgs, ... }: (treefmtEval pkgs).config.build.wrapper);
      checks = utils.eachSystem (
        { system, pkgs }:
        {
          formatting = (treefmtEval pkgs).config.build.check self;
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              deadnix.enable = true;
              ripsecrets.enable = true;
            };
          };
        }
      );

      packages = utils.eachSystem (
        { pkgs, ... }:
        {
          default = import ./hosts/iso/run.nix {
            inherit pkgs;
            iso = nixosConfigurations.iso.config.system.build.isoImage;
          };
        }
      );
    };
}
