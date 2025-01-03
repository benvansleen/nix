{
  config,
  lib,
  systemConfig,
  ...
}:

let
  inherit (lib) mkIf mkOption types;
  inherit (systemConfig.modules.system) impermanence;

  systemUsesImpermanence = impermanence.enable;
  cfg = config.modules.home.impermanence;
in
{
  options.modules.home.impermanence = {
    homeDir = mkOption {
      description = "Home directory structure";
      type =
        with types;
        submodule {
          options = {
            root = mkOption {
              type = str;
              description = "Home directory root";
            };
            config = mkOption {
              type = str;
              default = ".config";
              description = "XDG_CONFIG_HOME";
            };
            data = mkOption {
              type = str;
              default = ".local/share";
              description = "XDG_DATA_HOME";
            };
            state = mkOption {
              type = str;
              default = ".local/state";
              description = "XDG_STATE_HOME";
            };
            cache = mkOption {
              type = str;
              default = ".cache";
              description = "XDG_CACHE_HOME";
            };
          };
        };
    };
    persistDir = mkOption {
      type = types.str;
      default = "${impermanence.persistRoot}${cfg.homeDir.root}";
      description = "Where to persist files";
    };

    persistedFiles = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Files to persist";
    };

    persistedDirectories = mkOption {
      type =
        with types;
        listOf (oneOf [
          str
          (attrsOf str)
        ]);
      default = [ ];
      description = "Directories to persist";
    };
  };

  config =
    with lib;
    let
      replace-home-dir = replaceStrings [ "@config@" "@data@" "@state@" "@cache@" ] (
        with cfg.homeDir;
        [
          "${cfg.homeDir.config}"
          "${data}"
          "${state}"
          "${cache}"
        ]
      );
      files = map replace-home-dir cfg.persistedFiles;
      directories = map (
        dir:
        let
          dir' = if isAttrs dir then dir else { directory = dir; };
        in
        dir' // { directory = replace-home-dir dir'.directory; }
      ) cfg.persistedDirectories;
    in
    mkIf systemUsesImpermanence {
      home.persistence.${cfg.persistDir} = {
        inherit directories;
        files = [ ".ssh/known_hosts" ] ++ files;
        allowOther = true;
      };

      home.activation."rm-persisted-files" = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        for f in ${toString config.home.persistence.${cfg.persistDir}.files}; do
            echo "Removing $f"
            rm $f || true
        done
      '';
    };
}
