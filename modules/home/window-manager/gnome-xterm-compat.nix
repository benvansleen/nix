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
  cfg = config.modules.window-manager.gnome-xterm-compat;
in
{
  options.modules.window-manager.gnome-xterm-compat = {
    enable = mkEnableOption "link terminal emulator to `xterm` for compatibility w/ gnome default launcher (e.g. for launching terminal apps via `wofi drun`)";
    terminal = mkOption {
      type = types.package;
      description = "terminal emulator to link to `xterm`";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "xterm" ''
        ${lib.getExe cfg.terminal} "$@"
      '')
    ];
  };
}
