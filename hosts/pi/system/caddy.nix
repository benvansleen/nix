{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.caddy;

in
{
  options.modules.caddy.enable = mkEnableOption "caddy";

  imports = [
    (lib.tailscale-oci-container {
      inherit (cfg) enable;
      inherit config;
      container = {
        hostname = "caddy";
        image = "caddybuilds/caddy-cloudflare:latest";
        volumes = [
          "/etc/caddy/conf:/etc/caddy"
          "/etc/caddy/site:/srv"
          "/etc/caddy/data:/data"
          "/etc/caddy/config:/config"
        ];
      };

      ## Otherwise, podman & pihole will fight for :53
      dependsOn = [ "pihole" ];
    })
  ];

  config = mkIf cfg.enable {
    system.activationScripts.mk-caddy-state-dirs.text = ''
      mkdir -p /etc/caddy/conf
      mkdir -p /etc/caddy/site
      mkdir -p /etc/caddy/data
      mkdir -p /etc/caddy/config
    '';

    sops.templates."Caddyfile".content =
      let
        domain = "benvansleen.dev";
        pi = "100.85.59.37";
      in
      ''
        {
          email benvansleen@gmail.com
        }

        (cloudflare) {
          tls {
            dns cloudflare ${config.sops.placeholder.cloudflare_caddy_api_token}
          }
        }

        ${domain} {
          import cloudflare
          redir https://net.${domain}
        }

        net.${domain} {
          import cloudflare
          redir https://searx.net.${domain}
        }

        *.net.${domain} {
          import cloudflare

          @searx host searx.net.${domain}
          handle @searx {
            encode zstd gzip
            reverse_proxy ${pi}:${toString config.modules.searx.port}
          }

          @pihole host pihole.net.${domain}
          handle @pihole {
            encode zstd gzip
            redir / /admin{uri}
            reverse_proxy ${pi}:${toString config.modules.pihole.web-ui-port}
          }

          handle {
            abort
          }
        }
      '';
    environment.etc."/caddy/conf/Caddyfile" = {
      mode = "0400";
      source = config.sops.templates."Caddyfile".path;
    };
  };
}
