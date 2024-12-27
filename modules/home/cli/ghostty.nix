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
      description = "contents of ~/.config/ghostty/config";
      type =
        with types;
        submodule {
          options = {
            options = mkOption {
              description = "attrs of \"option = value\" definitions";
              type = attrsOf str;
              default = [ ];
            };
            keybinds = mkOption {
              description = "list of \"trigger = action\" definitions";
              type = attrsOf str;
              default = [ ];
            };
          };
        };
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

      file."${config.xdg.configHome}/ghostty/config".text =
        with lib;
        let
          join = concatStringsSep "\n";
          kvToString = mapAttrsToList (name: value: "${name}=${value}");
        in
        join [
          (join (kvToString cfg.settings.options))
          (join (map (bind: "keybind = ${bind}") (kvToString cfg.settings.keybinds)))
        ];
    };
  };
}
