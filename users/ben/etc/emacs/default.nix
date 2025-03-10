{ pkgs, ... }:

{
  config = {
    home.packages = with pkgs; [
      delta # required for `magit-delta`
    ];

    modules.impermanence.persistedDirectories = [ "@config@/emacs/var" ];

    modules.emacs = {
      init-el = ./init.el;
      framesOnlyMode = true;
      dashboard-img = ./floating-gnu-flute.png;
    };
  };
}
