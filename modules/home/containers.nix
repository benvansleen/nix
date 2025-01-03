{ lib, systemConfig, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = systemConfig.modules.system.containers;
in
{
  options.modules.home.containers.enable = mkEnableOption "rootless OCI containerization support";

  config = mkIf cfg.enable {
    services.podman.enable = true;
    modules.home.impermanence.persistedDirectories = [
      {
        directory = "@data@/containers";
        method = "symlink";
      }
      "@cache@/containers"
    ];
  };
}
