{ config, pkgs, ... }:

let
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

}
