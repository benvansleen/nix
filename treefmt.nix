_:

{
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;
  programs.statix.enable = true;
  programs.beautysh.enable = true;
  programs.shellcheck.enable = true;
  # List of formatters available at https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
}
