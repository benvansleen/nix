{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    types
    ;
  cfg = config.modules.home.cli.ghostty;
in
{
  options.modules.home.cli.ghostty = {
    enable = mkEnableOption "ghostty";
    settings = mkOption {
      type = types.listOf types.str;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        ghostty
      ];

      file."${config.xdg.configHome}/ghostty/config".text = lib.concatStringsSep "\n" cfg.settings;
    };
  };
}
