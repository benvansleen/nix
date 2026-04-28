{ inputs, ... }:

{
  flake-file.inputs = {
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  imports = [
    inputs.git-hooks.flakeModule
  ];

  perSystem =
    { config, ... }:
    {
      pre-commit.settings = {
        hooks = {
          check-added-large-files.enable = true;
          check-merge-conflicts.enable = true;
          detect-private-keys.enable = true;
          deadnix = {
            enable = true;
            settings.exclude = [ "generated" ];
          };
          end-of-file-fixer.enable = true;
          flake-checker.enable = true;
          ripsecrets.enable = true;
          statix = {
            enable = true;
            settings = {
              config = "statix.toml";
              ignore = [ "generated" ];
            };
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
              exclude = [
                "*.patch"
                "generated/*"
              ];
            };
          };
        };
      };
    };
}
