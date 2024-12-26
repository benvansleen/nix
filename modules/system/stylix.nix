{
  config,
  pkgs,
  lib,
  stylix,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system.stylix;
in
{
  options.modules.system.stylix = {
    enable = mkEnableOption "stylix";
  };

  imports = [
    stylix.nixosModules.stylix
  ];

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      autoEnable = true;
      homeManagerIntegration.autoImport = true;
      image = ../users/ben/etc/wallpapers/pensacola-beach-dimmed.png;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-hard.yaml";
      fonts = with pkgs; {
        serif = {
          package = iosevka;
          name = "Iosevka Etoile";
        };
        sansSerif = {
          package = fira-code-nerdfont;
          name = "Fira Code";
        };
        monospace = {
          package = hack-font;
          name = "Hack";
        };
      };
    };
  };
}
