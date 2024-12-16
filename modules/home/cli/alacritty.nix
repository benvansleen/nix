{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home.cli.alacritty;
in
{
  options.modules.home.cli.alacritty = {
    enable = mkEnableOption "terminal";
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        cursor = {
          # blinkInterval = 750;
          unfocusedHollow = true;
          viModeStyle = "Block";
        };
      };
    };
  };
}
