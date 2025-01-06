{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system.pi-hole;
in
{
  options.modules.system.pi-hole.enable = mkEnableOption "pi-hole";

  config = mkIf cfg.enable {
    services.resolved.enable = false;
    environment.etc."resolv.conf".text = ''
      nameserver 127.0.0.1
      nameserver 1.1.1.1
    '';

    system.activationScripts.mk-pihole-persist-dirs.text = ''
      mkdir -p /etc/pihole
      mkdir -p /etc/dnsmasq.d
    '';
    sops.templates."pihole.env".content = ''
      TZ=America/New_York
      WEBPASSWORD=${config.sops.placeholder.pihole_webpassword}
    '';
    virtualisation.oci-containers.containers = {
      pi-hole = {
        image = "pihole/pihole:latest";
        ports = [
          "53:53/tcp"
          "53:53/udp"
          "67:67/udp"
          "80:80/tcp"
        ];
        environmentFiles = [
          config.sops.templates."pihole.env".path
        ];
        volumes = [
          "/etc/pihole:/etc/pihole"
          "/etc/dnsmasq.d:/etc/dnsmasq.d"
        ];
      };
    };
  };
}
