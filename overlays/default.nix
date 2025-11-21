{ lib, ... }@inputs:

with inputs;
[
  (final: _prev: {
    stable = import nixpkgs-stable {
      inherit (final) config;
      inherit (final.stdenv.hostPlatform) system;
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
      cargoHash = "sha256-nnkO4nR4wkZXSW0QpPlHz6C4o1L0peEkMnOBdy7Zcok=";
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
]
