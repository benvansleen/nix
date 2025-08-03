{ lib, constants, ... }:

let
  inherit (lib) mkIf;
in
{
  tailscale-host = host: "${host}.${constants.tailscale-domain}";
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
              /*
                In the event of podman overwriting magicDNS config,
                 1. `podman exec` into container
                 2. Set `/etc/resolv.conf` to
                  ```
                  nameserver <podman0-bridge-ip>
                  nameserver 100.100.100.100
                  search dns.podman <tailscale-domain>
                  ```
                 3. Restart container
                 4. Verify that `tailscale` has overwritten `/etc/resolv.conf`
              */
              TS_ACCEPT_DNS = "true";

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
              "--pull=newer"
              "--network=bridge"
            ];

            inherit dependsOn;
          };
        };
      };
    };
}
