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
      cargoHash = "sha256-NTCaJOrU+dcA2yuH9K8WPSDLbNJjMd1LyehXIdJOuUU=";
      cargoPatches = (prev.nushell.cargoPatches or [ ]) ++ [
        ./patches/nushell/cargo-toml.patch
        ./patches/nushell/cargo-lock.patch
      ];
      patches = [
        ./patches/nushell/add-custom-escape-sequence.patch
      ];
    };
  })

  emacs-overlay.overlays.default
  colmena.overlays.default
]
