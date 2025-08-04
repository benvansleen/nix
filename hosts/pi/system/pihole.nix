{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.pihole;
in
{
  options.modules.pihole = {
    enable = mkEnableOption "pihole";
    web-ui-port = mkOption {
      type = types.port;
      default = 8080;
      description = "port to serve pihole web UI on";
    };
    prometheus-exporter-port = mkOption {
      type = types.port;
      default = 9617;
      description = "port to serve exports from prometheus-pihole-exporter";
    };
  };

  config = mkIf cfg.enable {
    # DO NOT TOUCH DNS CONFIG
    # will likely break tailscale magicDNS, caddy, and other services
    modules.tailscale.tailscale-up-extra-args = [
      "--accept-dns=true" # Verify tailscale overwrites /etc/resolv.conf!
    ];
    services.resolved.enable = false;

    # Must open ports to use pihole for LAN
    networking.firewall = {
      allowedTCPPorts = lib.mkForce [ 53 ];
      allowedUDPPorts = lib.mkForce [ 53 ];
    };

    virtualisation.oci-containers.containers = {
      pihole-exporter = mkIf config.modules.prometheus.client.enable {
        image = "ekofr/pihole-exporter:v1.2.0";
        environment = {
          PIHOLE_HOSTNAME = "127.0.0.1";
          PIHOLE_PORT = toString cfg.web-ui-port;
          PORT = "9617";
        };
        environmentFiles = [
          config.sops.templates."pihole.env".path
        ];
        ports = [
          "${toString cfg.prometheus-exporter-port}:9617"
        ];
        extraOptions = [
          "--network=host"
        ];
        dependsOn = [
          "pihole"
        ];
      };

      pihole = {
        hostname = "pihole";
        image = "pihole/pihole:2025.07.1";
        environment = {
          TZ = "America/New_York";
          PIHOLE_INTERFACE = "end0"; # rpi4 uses `end0` instead of `eth0`
          FTLCONF_dns_upstreams = "127.0.0.1#${toString config.modules.unbound.port}";
          FTLCONF_webserver_port = toString cfg.web-ui-port;
          FTLCONF_dns_dnssec = mkIf config.modules.unbound.enable "false";
          FTLCONF_dns_listeningMode = "all";
          FTLCONF_webserver_session_timeout = "604800";
        };
        environmentFiles = [
          config.sops.templates."pihole.env".path
        ];
        volumes = [
          "/etc/pihole:/etc/pihole"
          "/etc/dnsmasq.d:/etc/dnsmasq.d"
        ];
        extraOptions = [
          ## ALWAYS PULL NEW IMAGES IMPERATIVELY BEFORE APPLYING CONFIG
          ## `sudo podman pull pihole/pihole:<tag>`
          "--pull=never"

          # If facing any issues with DNS resolution on pihole startup,
          # ensure `Permit all origins` is set in web ui
          # TODO: verify that this issue is fixed by `DNSMASQ_LISTENING`
          "--network=host"
        ];
      };
    };
    system.activationScripts.mk-pihole-persist-dirs.text = ''
      mkdir -p /etc/pihole
      mkdir -p /etc/dnsmasq.d
    '';
    sops.templates."pihole.env".content = ''
      FTLCONF_webserver_api_password=${config.sops.placeholder.pihole_webpassword}
      PIHOLE_PASSWORD=${config.sops.placeholder.pihole_webpassword}
    '';
  };
}
