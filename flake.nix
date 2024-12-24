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

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      run = import ./run;
      overlays = import ./overlays inputs;
      utils = import ./utils.nix inputs;
      globals = (import ./common/globals.nix) // utils;

      treefmtEval = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      mkSystem = utils.mkSystem { inherit globals overlays nixpkgs; };
    in
    rec {

      nixosConfigurations = {
        amd = mkSystem "x86_64-linux" [
          ./hosts/amd
        ];
        qemu = mkSystem "x86_64-linux" [
          ./hosts/qemu
        ];
        iso = mkSystem "x86_64-linux" [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./hosts/iso
        ];
      };

      # homeConfigurations = {
      #   "ben@qemu" = nixosConfigurations.qemu.config.home-manager.users.ben.home;
      # };

      packages = utils.eachSystem (
        { pkgs, ... }:
        rec {
          default = rebuild;

          rebuild = run.rebuild pkgs;
          install = run.install-nixos pkgs;

          set-user-password = run.set-password-for pkgs "./secrets/user-password.sops";
          set-root-password = run.set-password-for pkgs "./secrets/root-password.sops";

          iso = nixosConfigurations.iso.config.system.build.isoImage;
          test-iso = import ./hosts/iso/run.nix {
            inherit pkgs;
            iso = nixosConfigurations.iso.config.system.build.isoImage;
          };

        }
      );

      devShells = utils.eachSystem (
        { pkgs, system }:
        {
          default =
            with pkgs;
            mkShell {
              buildInputs = [
                self.checks.${system}.pre-commit-check.enabledPackages
                sops
              ];
              shellHook =
                self.checks.${system}.pre-commit-check.shellHook
                + ''
                  export SOPS_AGE_KEY=$(${ssh-to-age}/bin/ssh-to-age -i ~/.ssh/master -private-key)
                '';
            };
        }

      );

      formatter = utils.eachSystem ({ pkgs, ... }: (treefmtEval pkgs).config.build.wrapper);
      checks = utils.eachSystem (
        { system, pkgs }:
        {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              deadnix.enable = true;
              ripsecrets.enable = true;
              statix.enable = true;
              nix-fmt = {
                enable = true;
                name = "nix fmt";
                entry = "${pkgs.nix}/bin/nix fmt";
                language = "system";
                stages = [ "pre-commit" ];
              };
            };
          };
        }
      );

    };
}
