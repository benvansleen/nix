{ lib, osConfig, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = osConfig.modules.containers;
in
{
  options.modules.containers.enable = mkEnableOption "rootless OCI containerization support";

  config = mkIf cfg.enable {
    services.podman.enable = true;
    modules.impermanence.persistedDirectories = [
      "@data@/containers"
      "@cache@/containers"
    ];
  };
}
