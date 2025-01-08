{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.cli.starship;
in
{
  options.modules.cli.starship = {
    enable = mkEnableOption "starship";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
    };
  };
}
