_:

{
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    ".envrc"
    "*.el"
    "*.sops*"
  ];

  programs.nixfmt.enable = true;
  programs.statix.enable = true;
  programs.beautysh.enable = true;
  programs.shellcheck.enable = true;
  programs.jsonfmt.enable = true;
  programs.yamlfmt.enable = true;

  # List of formatters available at https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
}
