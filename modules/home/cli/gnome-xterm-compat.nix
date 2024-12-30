{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.home.cli.gnome-xterm-compat;
in
{
  options.modules.home.cli.gnome-xterm-compat = {
    enable = mkEnableOption "link terminal emulator to `xterm` for compatibility w/ gnome default launcher (e.g. for launching terminal apps via `wofi drun`)";
    term = mkOption {
      type = types.package;
      description = "terminal emulator to link to `xterm`";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "xterm" ''
        ${lib.getExe cfg.term} "$@"
      '')
    ];
  };
}
