{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.features.alacritty;
in
{
  options.features.alacritty = {
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
