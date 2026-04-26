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
        # inputs.opencode.overlays.default
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

      ## upstream overlay currently broken: https://github.com/anomalyco/opencode/issues/23719
      opencode =
        inputs.opencode.packages.${final.stdenv.hostPlatform.system}.opencode.overrideAttrs
          (old: {
            preBuild = (old.preBuild or "") + /* sh */ ''
              substituteInPlace packages/opencode/src/cli/cmd/generate.ts \
                --replace-fail 'const prettier = await import("prettier")' 'const prettier: any = { format: async (s: string) => s }' \
                --replace-fail 'const babel = await import("prettier/plugins/babel")' 'const babel = {}' \
                --replace-fail 'const estree = await import("prettier/plugins/estree")' 'const estree = {}'
              substituteInPlace package.json \
                --replace-fail '"packageManager": "bun@1.3.13"' '"packageManager": "bun@${final.bun.version}"'
            '';
          });
    };
  };
}
