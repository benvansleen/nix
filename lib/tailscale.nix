{ lib, ... }:

let
  inherit (lib) mkIf;
in
{
  tailscale-oci-container =
    {
      enable ? true,
      config,
      container,
      dependsOn ? [ ],
    }:
    let
      name = container.hostname;
      sidecar = "ts-${container.hostname}";
      sidecar-state-dir = "/var/lib/tailscale-sidecars/${sidecar}/state";
    in
    {
      config = mkIf enable {
        system.activationScripts."mk-${sidecar}-state-dirs".text = ''
          mkdir -p ${sidecar-state-dir}
        '';
        sops.templates."${sidecar}.env".content = ''
          TS_AUTHKEY=${config.sops.placeholder.tailscale_sidecar_authkey}
        '';
        virtualisation.oci-containers.containers = {
          ${name} = container // {
            dependsOn = [ sidecar ];
            extraOptions = [
              "--network=container:${sidecar}"
            ];
          };

          ${sidecar} = {
            image = "tailscale/tailscale:latest";
            inherit (container) hostname;
            environment = {
              TS_STATE_DIR = "/var/lib/tailscale";
              TS_USERSPACE = "false";
            };
            environmentFiles = [
              config.sops.templates."${sidecar}.env".path
            ];
            volumes = [
              "${sidecar-state-dir}:/var/lib/tailscale"
            ];
            extraOptions = [
              "--device=/dev/net/tun"
              "--cap-add=net_admin"
              "--pull=always"
            ];

            inherit dependsOn;
          };
        };
      };
    };
}
