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
    optionals
    types
    ;
  cfg = config.modules.cli.ghostty;

  ghostty-config = "${config.xdg.configHome}/ghostty";
in
{
  options.modules.cli.ghostty = {
    enable = mkEnableOption "ghostty";
    package = mkOption {
      description = "ghostty package";
      type = types.package;
      default = pkgs.ghostty;
    };
    settings = mkOption {
      description = "contents of ~/.config/ghostty/config";
      type =
        with types;
        submodule {
          options = {
            options = mkOption {
              description = "attrs of \"option = value\" definitions";
              type = attrsOf str;
              default = { };
            };
            keybinds = mkOption {
              description = "list of \"trigger = action\" definitions";
              type = attrsOf str;
              default = { };
            };
            custom-shaders = mkOption {
              description = "paths to shader files";
              type = listOf str;
              default = [ ];
            };
            useStylixTheme = mkEnableOption "use stylix theme";
          };
        };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];

      file."${ghostty-config}/config".text =
        with lib;
        let
          join = concatStringsSep "\n";
          kvToString = mapAttrsToList (name: value: "${name}=${value}");
        in
        join (
          [
            (join (map (shaderPath: "custom-shader = ${shaderPath}") cfg.settings.custom-shaders))
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
        text =
          let
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
            palette = 0=${theme.base00}
            palette = 1=${theme.base08}
            palette = 2=${theme.base09}
            palette = 3=${theme.base0A}
            palette = 4=${theme.base0B}
            palette = 5=${theme.base0C}
            palette = 6=${theme.base0D}
            palette = 7=${theme.base04}
            palette = 8=${theme.base0F}
            palette = 9=${theme.base09}
            palette = 10=${theme.base02}
            palette = 11=${theme.base03}
            palette = 12=${theme.base0E}
            palette = 13=${theme.base05}
            palette = 14=${theme.base06}
            palette = 15=${theme.base07}
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
