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
      "--accept-dns=true" # Verify tailscale overwrites /etc/resolv.conf!
    ];
    services.resolved.enable = false;

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
          PIHOLE_DNS_ = "100.64.0.3"; # mullvad dns
          PIHOLE_INTERFACE = "end0"; # rpi4 uses `end0` instead of `eth0`
          WEB_PORT = toString cfg.web-ui-port;
          TZ = "America/New_York";
          DNSSEC = mkIf config.modules.unbound.enable "false";
          CACHE_SIZE = mkIf config.modules.unbound.enable "0";
          DNSMASQ_LISTENING = "all";
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
          # "--pull=newer"

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
      WEBPASSWORD=${config.sops.placeholder.pihole_webpassword}
    '';
  };
}
