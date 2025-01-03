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

    stylix = {
      url = "github:danth/stylix";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        flake-compat.follows = "flake-compat";
      };
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };

    ghostty = {
      url = "github:ghostty-org/ghostty/main";
      inputs = {
        nixpkgs-stable.follows = "nixpkgs";
        nixpkgs-unstable.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    hyprbar = {
      url = "github:benvansleen/hyprbar";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      pre-commit-hooks,
      treefmt-nix,
      ...
    }@inputs:
    let
      treefmtEval = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      run = import ./run;
      overlays = import ./overlays inputs;
      lib = nixpkgs.lib.extend (
        _final: _prev: home-manager.lib // (import ./lib.nix lib overlays inputs)
      );
    in
    {

      nixosConfigurations = {
        amd = lib.mkSystem "x86_64-linux" [
          ./hosts/amd
        ];
        qemu = lib.mkSystem "x86_64-linux" [
          ./hosts/qemu
        ];
        iso = lib.mkSystem "x86_64-linux" [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./hosts/iso
        ];
      };

      homeConfigurations =
        let
          amd = self.nixosConfigurations.amd.config;
        in
        {
          "ben@${amd.machine.name}" = home-manager.lib.homeManagerConfiguration {
            inherit (amd.home-manager.extraSpecialArgs) pkgs;
            modules = lib.allHomeModules ++ [
              (import ./users/ben/home.nix {
                user = "ben";
                directory = "/home/ben";
              })
            ];
            extraSpecialArgs = amd.home-manager.extraSpecialArgs // {
              inherit lib;
            };
          };
        };

      packages = lib.eachSystem (
        { pkgs, ... }:
        rec {
          default = rebuild;

          rebuild = run.rebuild pkgs;
          install = run.install-nixos pkgs;

          set-user-password = run.set-password-for pkgs "./secrets/user-password.sops";
          set-root-password = run.set-password-for pkgs "./secrets/root-password.sops";

          iso = self.nixosConfigurations.iso.config.system.build.isoImage;
          test-iso = import ./hosts/iso/run.nix {
            inherit pkgs;
            iso = self.nixosConfigurations.iso.config.system.build.isoImage;
          };

        }
      );

      devShells = lib.eachSystem (
        { pkgs, system }:
        {
          default =
            with pkgs;
            mkShell {
              buildInputs = [
                self.checks.${system}.pre-commit-check.enabledPackages
                nixfmt-rfc-style
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

      formatter = lib.eachSystem ({ pkgs, ... }: (treefmtEval pkgs).config.build.wrapper);
      checks = lib.eachSystem (
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
