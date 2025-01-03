{ pkgs, ... }:

{
  config = {
    home.packages = with pkgs; [
      delta # required for `magit-delta`
    ];

    modules.home.impermanence.persistedDirectories = [ "@config@/emacs/var" ];

    modules.home.emacs = {
      init-el = ./init.el;
      framesOnlyMode = true;
      dashboard-img = ./floating-gnu-flute.png;
    };
  };
}
