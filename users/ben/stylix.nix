{ pkgs, ... }:

{
  stylix = {
    enable = true;
    autoEnable = true;
    image = ./etc/wallpapers/pensacola-beach-dimmed.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-hard.yaml";
    fonts.sizes = {
      applications = 12; # governs firefox
      desktop = 14;
      popups = 14;
      terminal = 14;
    };
  };
}
