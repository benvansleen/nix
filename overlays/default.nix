{ lib, ... }@inputs:

with inputs;
[
  (final: _prev: {
    stable = import nixpkgs-stable {
      inherit (final.stdenv.hostPlatform) system;
      inherit (final) config;
    };
  })

  (final: _prev: {
    unfree = import nixpkgs {
      inherit (final.stdenv.hostPlatform) system;
      config = final.config // {
        allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "copilot-language-server"
            "keymapp"
            "zsh-abbr"
          ];
      };
    };
  })

  (final: prev: {
    nushell = prev.nushell.overrideAttrs (old: rec {
      src = final.fetchFromGitHub {
        owner = "benvansleen";
        repo = old.pname;
        rev = "test/keychords-and-skim";
        hash = "sha256-0HYczT0iA1r8VIt8HJ4hw6McM3m9wVSbDZvKt0P5+m4=";
      };
      cargoBuildFeatures = [ "skim" ];
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-teoexaaYib4JbYaxE4NRrffLLO1DqjQPv02tRiqtt0s=";
      };
    });
  })

  (final: _prev: {
    inherit (final.unfree) copilot-language-server;
    ollama-copilot = final.buildGoModule rec {
      pname = "ollama-copilot";
      version = "master";
      src = final.fetchFromGitHub {
        owner = "benvansleen";
        repo = pname;
        rev = "master";
        hash = "sha256-Qg/hx9/iEm4aYTalcwkPgFDMeDxe5M5fvzdqCldXr88=";
      };

      vendorHash = "sha256-g27MqS3qk67sve/jexd07zZVLR+aZOslXrXKjk9BWtk=";

      meta = {
        mainProgram = pname;
        description = "Proxy that allows you to use ollama as a copilot like Github copilot";
        homepage = "https://github.com/bernardo-bruning/ollama-copilot";
        license = lib.licenses.mit;
      };
    };
  })

  emacs-overlay.overlays.default

  (final: _prev: {
    opencode = opencode.packages.${final.stdenv.hostPlatform.system}.default;
  })
]
