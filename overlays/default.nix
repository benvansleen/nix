{ lib, ... }@inputs:

with inputs;
[
  (final: _prev: {
    stable = import nixpkgs-stable {
      inherit (final) system config;
    };
  })

  (final: _prev: {
    unfree = import nixpkgs {
      inherit (final) system;
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

  (_final: prev: {
    nushell = prev.rustPlatform.buildRustPackage {
      inherit (prev.nushell)
        src
        version
        name
        pname
        buildInputs
        nativeBuildInputs
        propagatedBuildInputs
        checkPhase
        passthru
        meta
        ;
      cargoHash = "sha256-HARErJeB0bJnHLnLjg5vqJyHWLSdU7d8HMFcdVd/YcI=";
      cargoPatches = (prev.nushell.cargoPatches or [ ]) ++ [
        ./patches/nushell/cargo.patch
      ];
      patches = (prev.nushell.patches or [ ]) ++ [
        ./patches/nushell/add-custom-escape-sequence.patch
      ];
    };
  })

  (prev: final: {
    inherit (final.unfree) copilot-language-server;
    ollama-copilot = prev.buildGoModule rec {
      pname = "ollama-copilot";
      version = "master";
      src = prev.fetchFromGitHub {
        owner = "bernardo-bruning";
        repo = pname;
        rev = "d6ab7a2fc9d94d61b12a5eb36efe8126346ea9cc";
        hash = "sha256-eq9HlJ0+0cAF7jFCvflEMVAZYVKMBmzLRO8oUQox2ig=";
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
  colmena.overlays.default
]
