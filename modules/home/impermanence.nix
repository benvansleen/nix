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
      type = types.listOf types.str;
      default = [ ];
      description = "Files to persist";
    };

    persistedDirectories = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Directories to persist";
    };
  };

  config =
    let
      replace-home-dirs =
        with builtins;
        map (
          dir:
          replaceStrings [ "@config@" "@data@" "@state@" "@cache@" ] (with cfg.homeDir; [
            "${cfg.homeDir.config}"
            "${data}"
            "${state}"
            "${cache}"
          ]) dir
        );
      files = replace-home-dirs cfg.persistedFiles;
      directories = replace-home-dirs cfg.persistedDirectories;
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
