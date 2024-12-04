{
  description = "NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      systems,
      treefmt-nix,
    }:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

      treefmtEval = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    rec {
      nixosConfigurations = {
        qemu = import ./hosts/qemu { inherit nixpkgs home-manager; };
      };

      # homeConfigurations = {
      #   "ben@qemu" = nixosConfigurations.qemu.config.home-manager.users.ben.home;
      # };

      formatter = eachSystem (pkgs: (treefmtEval pkgs).config.build.wrapper);
      checks = eachSystem (pkgs: {
        formatting = (treefmtEval pkgs).config.build.check self;
      });
    };
}
