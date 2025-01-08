{ lib, systemConfig, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = systemConfig.modules.containers;
in
{
  options.modules.containers.enable = mkEnableOption "rootless OCI containerization support";

  config = mkIf cfg.enable {
    services.podman.enable = true;
    modules.impermanence.persistedDirectories = [
      {
        directory = "@data@/containers";
        method = "symlink";
      }
      "@cache@/containers"
    ];
  };
}
