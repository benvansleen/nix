{ config, lib, ... }:

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
  };

  config = mkIf cfg.enable {
    # DO NOT TOUCH DNS CONFIG
    # will likely break tailscale magicDNS, caddy, and other services
    modules.tailscale.tailscale-up-extra-args = [
      "--accept-dns=true"
    ];
    services.resolved.enable = false;
    environment.etc."resolv.conf".text = ''
      nameserver 127.0.0.1
      nameserver 1.1.1.1
    '';

    virtualisation.oci-containers.containers = {
      pihole = {
        hostname = "pihole";
        # image = "cbcrowe/pihole-unbound:latest";
        image = "pihole/pihole:latest";
        ports = [
          "53:53/tcp"
          "53:53/udp"
          "67:67/udp" # For DHCP
          "${toString cfg.web-ui-port}:80/tcp" # For pihole dashboard
        ];
        environment = {
          # PIHOLE_DNS_ = "127.0.0.1#5335";
          TZ = "America/New_York";
          DNSSEC = "true";
          DNSMASQ_LISTENING = "single";
        };
        environmentFiles = [
          config.sops.templates."pihole.env".path
        ];
        volumes = [
          "/etc/pihole:/etc/pihole"
          "/etc/dnsmasq.d:/etc/dnsmasq.d"
        ];
        extraOptions = [
          "--pull=newer"
        ];
      };
    };
    system.activationScripts.mk-pihole-persist-dirs.text = ''
      mkdir -p /etc/pihole
      mkdir -p /etc/dnsmasq.d
    '';
    sops.templates."pihole.env".content = ''
      WEBPASSWORD=${config.sops.placeholder.pihole_webpassword}
    '';
  };
}
