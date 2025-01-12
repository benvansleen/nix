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

    # Must open ports to use pihole for LAN
    networking.firewall = {
      allowedTCPPorts = lib.mkForce [ 53 ];
      allowedUDPPorts = lib.mkForce [ 53 ];
    };

    virtualisation.oci-containers.containers = {
      pihole = {
        hostname = "pihole";
        image = "pihole/pihole:latest";
        environment = {
          PIHOLE_DNS_ = "127.0.0.1#${toString config.modules.unbound.port}";
          PIHOLE_INTERFACE = "end0"; # rpi4 uses `end0` instead of `eth0`
          WEB_PORT = toString cfg.web-ui-port;
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
          "--network=host"
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
