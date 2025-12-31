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
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
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
    nixos-hardware.url = "github:nixos/nixos-hardware";

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

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit.inputs.flake-compat.follows = "flake-compat";
      };
    };

    nixos-cli = {
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
      url = "github:benvansleen/hyprbar/add-laptop-config";
      inputs = {
        ## hyprbar needs its own `nixpkgs` until migration to current version of astal
        # nixpkgs.follows = "nixpkgs-stable";
        systems.follows = "systems";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };

    centerpiece = {
      url = "github:friedow/centerpiece";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    clonix = {
      url = "github:benvansleen/clonix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    extra-container = {
      url = "github:erikarvstedt/extra-container";
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
      pre-commit-hooks,
      treefmt-nix,
      ...
    }@inputs:
    let
      lib = import ./lib inputs;
      mkSystem = lib.mkSystem (import ./overlays (inputs // { inherit lib; }));
    in
    {
      nixosConfigurations = {
        amd = mkSystem ./hosts/amd;
        laptop = mkSystem ./hosts/laptop;
        pi = mkSystem ./hosts/pi;
      };

      apps = lib.eachSystem (
        pkgs: _:
        let
          run = import ./run { inherit pkgs lib; };
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

      devShells = lib.eachSystem (
        pkgs: system: {
          default =
            with pkgs;
            mkShell {
              buildInputs = [
                self.checks.${system}.pre-commit-check.enabledPackages
              ];
              inherit (self.checks.${system}.pre-commit-check) shellHook;
            };
        }
      );

      formatter = lib.eachSystem (
        pkgs: _: (treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build.wrapper
      );
      checks = lib.eachSystem (
        _: system: {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
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
                packageOverrides.treefmt = self.outputs.formatter.${system};
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
        }
      );
    };
}
