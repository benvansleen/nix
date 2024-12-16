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
        fira-code-nerdfont
        hack-font
      ];

      fontconfig = {
        defaultFonts = {
          serif = [ "Hack" ];
          sansSerif = [ "Fira Code" ];
          monospace = [ "Hack" ];
        };
      };
    };
  };
}
