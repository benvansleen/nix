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
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    systems.url = "github:nix-systems/default";
    secrets = {
      url = "git+ssh://git@github.com/benvansleen/secrets.git";
      # url = "path:/home/ben/.config/nix/secrets";
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
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };

    nvim = {
      url = "github:benvansleen/nvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    hyprbar = {
      url = "github:benvansleen/hyprbar";
      inputs = {
        nixpkgs.follows = "nixpkgs-stable";
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
      colmenaHive = colmena.lib.makeHive (import ./hive { inherit inputs lib overlays; });

      apps = lib.eachSystem (
        pkgs:
        let
          run = import ./run { inherit pkgs lib colmena; };
          create-app = pkg: {
            type = "app";
            program = lib.getExe pkg;
          };
          set-password-for = user: create-app (run.set-password-for user);
        in
        with lib;
        (pipe run [
          (filterAttrs (name: value: (builtins.typeOf value) == "set" && !hasPrefix "override" name))
          (mapAttrs (_name: create-app))
        ])
        // (pipe { root = set-password-for "root"; } [
          (attrs: attrs // (eachUser set-password-for))
          (mapAttrs' (user: app: nameValuePair "set-password-for-${user}" app))
        ])
      );

      devShells = lib.eachSystem (pkgs: {
        default =
          with pkgs;
          mkShell {
            buildInputs = [
              self.checks.${system}.pre-commit-check.enabledPackages
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
            check-added-large-files.enable = true;
            check-merge-conflicts.enable = true;
            detect-private-keys.enable = true;
            deadnix.enable = true;
            end-of-file-fixer.enable = true;
            flake-checker.enable = true;
            ripsecrets.enable = true;
            statix = {
              enable = true;
              settings.config = "statix.toml";
            };
            treefmt = {
              enable = true;
              packageOverrides.treefmt = self.outputs.formatter.${pkgs.system};
            };
            typos = {
              enable = true;
              settings = {
                diff = false;
                ignored-words = [
                  "artic"
                  "facter"
                ];
                exclude = "*.patch";
              };
            };
          };
        };
      });
    };
}
