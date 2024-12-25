{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home.emacs;

  emacs-pkg = pkgs.emacs-pgtk;
  emacs = pkgs.emacsWithPackagesFromUsePackage {
    package =
      if cfg.native-build then
        emacs-pkg.overrideAttrs (_oldAttrs: {
          NIX_CFLAGS_COMPILE = "-O3 -pipe -march=native -fomit-frame-pointer";
        })
      else
        emacs-pkg;
    config = ./init.el;
    defaultInitFile = true;
    alwaysEnsure = true;
    alwaysTangle = true;
    extraEmacsPackages =
      epkgs: with epkgs; [
        treesit-grammars.with-all-grammars
      ];
  };
in
{

  options.modules.home.emacs = {
    enable = mkEnableOption "emacs";
    native-build = mkEnableOption "emacs with native build flags";
  };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = emacs;
    };

    services.emacs = {
      enable = true;
      package = emacs;
      defaultEditor = true;
      socketActivation.enable = true;
      client = {
        enable = true;
        arguments = [ "-nw" ];
      };
    };

  };
}
