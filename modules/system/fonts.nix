{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.fonts;
in
{
  options.modules.fonts = {
    enable = mkEnableOption "fonts";
  };

  config = mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs.nerd-fonts; [
        iosevka
        fira-code
        hack
        _3270
        victor-mono
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
