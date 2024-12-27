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

  ghostty-config = "${config.xdg.configHome}/ghostty";
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
            useStylixTheme = mkEnableOption "use stylix theme";
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

      file."${ghostty-config}/config".text =
        with lib;
        let
          join = concatStringsSep "\n";
          kvToString = mapAttrsToList (name: value: "${name}=${value}");
        in
        join (
          [
            (join (kvToString cfg.settings.options))
            (join (map (bind: "keybind = ${bind}") (kvToString cfg.settings.keybinds)))
          ]
          ++ optionals cfg.settings.useStylixTheme (kvToString {
            theme = "stylix";
          })
        );

      activation."create-ghostty-themes-dir" = mkIf cfg.settings.useStylixTheme (
        lib.hm.dag.entryBefore [ "linkGeneration" ] ''
          mkdir -p ${ghostty-config}/themes
        ''
      );
      file."${ghostty-config}/themes/stylix" = mkIf cfg.settings.useStylixTheme {
        text = let
            importYaml =
              file:
              builtins.fromJSON (
                builtins.readFile (
                  pkgs.runCommand "converted-yaml.json" { } ''${pkgs.yj}/bin/yj < "${file}" > "$out"''
                )
              );

            theme =
              if lib.isString config.stylix.base16Scheme then
                (importYaml config.stylix.base16Scheme).palette
              else
                config.stylix.base16Scheme;
          in
          ''
            palette = 0=#${theme.base00}
            palette = 1=#${theme.base08}
            palette = 2=#${theme.base09}
            palette = 3=#${theme.base0A}
            palette = 4=#${theme.base0B}
            palette = 5=#${theme.base0C}
            palette = 6=#${theme.base0D}
            palette = 7=#${theme.base0E}
            palette = 8=#${theme.base0F}
            palette = 9=#${theme.base09}
            palette = 10=#${theme.base02}
            palette = 11=#${theme.base03}
            palette = 12=#${theme.base04}
            palette = 13=#${theme.base05}
            palette = 14=#${theme.base06}
            palette = 15=#${theme.base07}
            background = ${theme.base00}
            foreground = ${theme.base05}
            cursor-color = ${theme.base05}
            selection-background = ${theme.base03}
            selection-foreground = ${theme.base05}
          '';
      };
    };
  };
}
