{ pkgs, osConfig, ... }:

{
  stylix = {
    enable = osConfig.machine.desktop;
    autoEnable = true;
    image = ./wallpapers/pensacola-beach-dimmed.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-hard.yaml";
    fonts.sizes = {
      applications = 12; # governs firefox & emacs
      desktop = 14;
      popups = 14;
      terminal = 14;
    };
  };
}
