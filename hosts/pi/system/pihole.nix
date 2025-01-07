{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system.pi-hole;
in
{
  options.modules.system.pi-hole.enable = mkEnableOption "pi-hole";

  config = mkIf cfg.enable {
    services.resolved.enable = false;

    virtualisation.oci-containers.containers = {
      pi-hole = {
        # image = "cbcrowe/pihole-unbound:latest";
        image = "pihole/pihole:latest";
        ports = [
          "53:53/tcp"
          "53:53/udp"
          "67:67/udp" # For DHCP
          "80:80/tcp" # For pihole dashboard
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
      };
    };
    system.activationScripts.mk-pihole-persist-dirs.text = ''
      mkdir -p /etc/pihole
      mkdir -p /etc/dnsmasq.d
    '';
    sops.templates."pihole.env".content = ''
      WEBPASSWORD=${config.sops.placeholder.pihole_webpassword}
    '';

    systemd.services.tailscale-serve-pihole = {
      description = "Serve pihole dashboard over tailscale";
      after = [
        "tailscale-serve-searx.service"
        "tailscale-autoconnect.service"
      ];
      wants = [
        "tailscale-autoconnect.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "simple";
      script = with pkgs; ''
        # Wait for `tailscale up` to settle
        sleep 2
        ${lib.getExe tailscale} serve --bg --set-path /pihole localhost:80/admin
      '';
    };
  };
}
