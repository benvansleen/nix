{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system.containers;
  inherit (config.modules.system) impermanence;
in
{
  options.modules.system.containers.enable = mkEnableOption "OCI containerization support";

  config = mkIf cfg.enable {
    # networking.firewall.interfaces.podman1.allowedUDPPorts = [ 53 ];

    virtualisation = {
      oci-containers.backend = "podman";
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
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
