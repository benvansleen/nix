{ pkgs, ... }:

{
  config = {
    home.packages = with pkgs; [
      delta # required for `magit-delta`
    ];

    impermanence.persistedDirectories = [ "@config@/emacs/var" ];
  };
}
