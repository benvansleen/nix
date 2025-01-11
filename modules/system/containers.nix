{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.containers;
  inherit (config.modules) impermanence;
in
{
  options.modules.containers = {
    enable = mkEnableOption "OCI containerization support";
    disable-podman-dns = mkEnableOption "disable DNS in podman";
  };

  config = mkIf cfg.enable {
    virtualisation = {
      oci-containers.backend = "podman";
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = !cfg.disable-podman-dns;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };
      containers.storage.settings = {
        storage = {
          driver = "overlay";
          graphroot = "/var/lib/containers/storage";
          runroot = "/run/containers/storage";
        };
      };
    };

    environment = {
      persistence = mkIf impermanence.enable {
        ${impermanence.persistRoot}.directories = [
          config.virtualisation.containers.storage.settings.storage.graphroot
        ];
      };

      systemPackages = with pkgs; [
        podman-compose
        podman-tui
        dive
      ];
    };
  };
}
