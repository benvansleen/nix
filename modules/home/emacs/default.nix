{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home.emacs;

  myEmacs = pkgs.emacsWithPackagesFromUsePackage {
    package = pkgs.emacs-pgtk;
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
  };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = myEmacs;
    };

    services.emacs = {
      enable = true;
      package = myEmacs;
      defaultEditor = true;
      socketActivation.enable = true;
      client = {
        enable = true;
        arguments = [ "-nw" ];
      };
    };

  };
}
