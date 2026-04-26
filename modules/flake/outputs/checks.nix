{ inputs, ... }:

{
  flake-file.inputs = {
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  perSystem =
    {
      config,
      system,
      ...
    }:
    {
      checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = ../../../.;
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
            packageOverrides.treefmt = config.formatter;
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
    };
}
