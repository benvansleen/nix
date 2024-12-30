{ home-dir, ... }:
{ lib, systemConfig, ... }@inputs:

let
  inherit (lib) mkIf mkOption types;
  inherit (systemConfig.modules.system) impermanence;
  cfg = inputs.config.impermanence;

  inherit (home-dir)
    root
    config
    data
    cache
    state
    ;
in
{
  options.impermanence = {
    persistDir = mkOption {
      type = types.str;
      default = "${impermanence.persistRoot}${root}";
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
          replaceStrings
            [ "@config@" "@data@" "@cache@" "@state@" ]
            [ "${config}" "${data}" "${cache}" "${state}" ]
            dir
        );
      persistedFiles = replace-home-dirs cfg.persistedFiles;
      persistedDirectories = replace-home-dirs cfg.persistedDirectories;
    in
    {
      home.persistence.${cfg.persistDir} = mkIf impermanence.enable {
        allowOther = true;
        directories = [
          "${config}/nix"
          "Code"
          "Documents"
          "Downloads"
          "Pictures"
        ] ++ persistedDirectories;
        files = [ ".ssh/known_hosts" ] ++ persistedFiles;
      };

      home.activation."rm-persisted-files" = mkIf impermanence.enable (
        lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          for f in ${toString inputs.config.home.persistence.${cfg.persistDir}.files}; do
              echo "Removing $f"
              rm $f || true
          done
        ''
      );
    };
}
