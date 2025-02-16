{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    systems.url = "github:nix-systems/default";
    secrets = {
      url = "git+ssh://git@github.com/benvansleen/secrets.git";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    home-manager = {
      url = "github:nix-community/home-manager";
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

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        stable.follows = "nixpkgs-stable";
        flake-compat.follows = "flake-compat";
      };
    };

    stylix = {
      url = "github:danth/stylix/release-24.11";
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
        nixpkgs-stable.follows = "nixpkgs-stable";
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

    clonix = {
      url = "github:benvansleen/clonix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
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
      colmena,
      pre-commit-hooks,
      treefmt-nix,
      ...
    }@inputs:
    let
      treefmtEval = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      overlays = import ./overlays (inputs // { inherit (nixpkgs) lib; });
      lib = nixpkgs.lib.extend (_final: _prev: home-manager.lib // (import ./lib lib inputs));
    in
    {
      colmena = import ./hive { inherit inputs lib overlays; };
      colmenaHive = colmena.lib.makeHive self.outputs.colmena;

      packages = lib.eachSystem (
        pkgs:
        let
          run = pkgs.callPackage ./run { inherit colmena; };
        in
        rec {
          default = rebuild;

          inherit (run)
            all
            rebuild
            apply
            build
            ;

          install = run.install-nixos;

          root.set-password = run.set-password-for "root";

          iso = self.nixosConfigurations.iso.config.system.build.isoImage;
          test-iso = import ./hosts/iso/run.nix {
            inherit pkgs;
            iso = self.nixosConfigurations.iso.config.system.build.isoImage;
          };

        }
        // (lib.eachUser (user: {
          set-password = run.set-password-for user;
        }))
      );

      devShells = lib.eachSystem (pkgs: {
        default =
          with pkgs;
          mkShell {
            buildInputs = [
              self.checks.${system}.pre-commit-check.enabledPackages
              nixfmt-rfc-style
              colmena.packages.${pkgs.system}.colmena
            ];
            inherit (self.checks.${system}.pre-commit-check) shellHook;
          };
      }

      );

      formatter = lib.eachSystem (pkgs: (treefmtEval pkgs).config.build.wrapper);
      checks = lib.eachSystem (pkgs: {
        pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
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
      });
    };
}
