{
  inputs,
  self,
  lib,
  ...
}:

{
  flake-file.inputs = {
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.overlaid = {
    nixpkgs = {
      overlays = [
        self.overlays.default
        self.overlays.local
        self.overlays.lib
        inputs.emacs-overlay.overlay
      ];

      config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "copilot-language-server"
          "keymapp"
          "zsh-abbr"
        ];
    };
  };

  flake.overlays = {
    default = final: _prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (final.stdenv.hostPlatform) system;
        inherit (final) config;
      };

      inherit (final.local) nushell;

      # opencode = inputs.opencode.packages.${final.stdenv.hostPlatform.system}.default;
    };
  };
}
