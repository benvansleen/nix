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

  emacs-overlay.overlays.default
  colmena.overlays.default
]
