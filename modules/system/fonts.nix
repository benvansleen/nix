{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system.fonts;
in
{
  options.modules.system.fonts = {
    enable = mkEnableOption "fonts";
  };

  config = mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        iosevka
        hack-font
        fira-code-nerdfont
      ];

      fontconfig = {
        defaultFonts = {
          serif = [ "Iosevka Etoile" ];
          sansSerif = [ "Iosevka Aile" ];
          monospace = [ "Hack" ];
        };
      };
    };
  };
}
