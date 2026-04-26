{ inputs, ... }:

let
  treefmt = {
    projectRootFile = "flake.nix";
    settings.global.excludes = [
      ".envrc"
      "*.el"
      "*.sops*"
      "*.png"
    ];

    programs = {
      nixfmt.enable = true;
      statix.enable = true;
      beautysh.enable = true;
      shellcheck.enable = true;
      jsonfmt.enable = true;
      yamlfmt.enable = true;
    };

    # List of formatters available at https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
  };
in
{
  flake-file.inputs = {
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      formatter = (inputs.treefmt-nix.lib.evalModule pkgs treefmt).config.build.wrapper;
    };
}
