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
    mkDefault
    optionals
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
    enableXtermAlias = mkEnableOption "enable xterm alias";
  };

  config = mkIf cfg.enable {
    modules.home.cli.ghostty.enableXtermAlias = mkDefault true;
    home = {
      packages =
        with pkgs;
        [
          ghostty
        ]
        ++ (optionals cfg.enableXtermAlias [
          (writeShellScriptBin "xterm" ''
            ${ghostty}/bin/ghostty "$@"
          '')
        ]);

      file."${config.xdg.configHome}/ghostty/config".text = lib.concatStringsSep "\n" cfg.settings;
    };
  };
}
