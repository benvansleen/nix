{
  flake.modules.homeManager.gnome-xterm-compat =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.modules.gnome-xterm-compat = with lib; {
        terminal = mkOption {
          type = types.package;
          description = "terminal emulator to link to `xterm`";
        };
      };

      config =
        let
          cfg = config.modules.gnome-xterm-compat;
        in
        {
          home.packages = [
            (pkgs.writeShellScriptBin "xterm" ''
              ${lib.getExe cfg.terminal} "$@"
            '')
          ];
        };
    };
}
