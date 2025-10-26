{
  config,
  pkgs,
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
  cfg = config.modules.caddy;
in
{
  options.modules.caddy = {
    enable = mkEnableOption "caddy";
    admin-port = mkOption {
      type = types.port;
      default = 2019;
      description = "port where caddy admin information is available";
    };
  };

  config = mkIf cfg.enable {
    sops.templates."caddy.env".content = ''
      TS_AUTHKEY=${config.sops.placeholder.tailscale_sidecar_authkey}
      CLOUDFLARE_TOKEN=${config.sops.placeholder.cloudflare_caddy_api_token}
    '';
    services.caddy =
      let
        services = {
          grafana = ''
            tailscale_auth
            encode zstd gzip
            reverse_proxy pi:${toString config.modules.grafana.port} {
              header_up X-Webauth-User {http.auth.user.tailscale_user}
            }
          '';
          maybe = ''
            encode zstd gzip
            reverse_proxy pi:${toString config.modules.maybe.port}
          '';
          pihole = ''
            encode zstd gzip
            redir / /admin{uri}
            reverse_proxy pi:${toString config.modules.pihole.web-ui-port}
          '';
          prometheus = ''
            encode zstd gzip
            reverse_proxy pi:${toString config.modules.prometheus.server.port}
          '';
          searx = ''
            encode zstd gzip
            reverse_proxy pi:${toString config.modules.searx.port}
          '';
        };

        tailscale = host: config: ''
          :443 {
            bind tailscale/${host}
            tls {
              get_certificate tailscale
            }
            ${config}
          }
        '';
        cloudflare = config: ''
          import cloudflare
          ${config}
        '';
      in
      rec {
        enable = true;
        enableReload = false;
        package = pkgs.caddy.withPlugins {
          plugins = [
            "github.com/tailscale/caddy-tailscale@v0.0.0-20250207163903-69a970c84556"
            "github.com/caddy-dns/cloudflare@v0.0.0-20250407183951-bbf79111721a"
          ];
          hash = "sha256-8nFRJukvi6amwvrpexj2ahghxZKOiGwWjTxeExE41PQ=";
        };
        inherit (lib.constants) email;
        dataDir = "/var/lib/caddy";
        logDir = "/var/log/caddy";

        environmentFile = config.sops.templates."caddy.env".path;
        logFormat = ''
          output file ${logDir}/caddy_main.log {
            roll_size 100MiB
            roll_keep 5
            roll_keep_for 100d
          }
          format json
          level INFO
        '';

        # TODO: restrict `admin :2019` to just tailnet ips
        # https://caddy.community/t/access-metrics-when-using-dockerized-caddy/16496
        globalConfig = ''
          on_demand_tls {
            ask http://localhost:9123/ask
          }

          tailscale {
            auth_key {$TS_AUTHKEY}
            webui true
          }

          admin :${toString cfg.admin-port}
          servers {
            metrics
          }
        '';
        extraConfig = ''
          https:// {
            tls {
              on_demand
            }
          }

          (cloudflare) {
            tls {
              dns cloudflare {$CLOUDFLARE_TOKEN}
            }
          }
        ''
        + (
          with lib;
          pipe services [
            (mapAttrsToList tailscale)
            (concatStringsSep "\n")
          ]
        );
        virtualHosts =
          let
            primary = {
              domain = "vansleen.dev";
              subdomain = "ben";
            };
            secondary = {
              domain = "benvansleen.dev";
              subdomain = "net";
            };
          in
          {
            "grafana.${primary.subdomain}.${primary.domain}" = {
              serverAliases = [
                "grafana.${secondary.subdomain}.${secondary.domain}"
              ];
              extraConfig = cloudflare ''
                redir / https://grafana.${lib.constants.tailscale-domain}
              '';
            };

            "maybe.${primary.subdomain}.${primary.domain}" = {
              serverAliases = [
                "maybe.${primary.domain}"
                "maybe.${secondary.subdomain}.${secondary.domain}"
              ];
              extraConfig = cloudflare services.maybe;
            };

            "pihole.${primary.subdomain}.${primary.domain}" = {
              serverAliases = [
                "pihole.${secondary.subdomain}.${secondary.domain}"
              ];
              extraConfig = cloudflare services.pihole;
            };

            "prometheus.${primary.subdomain}.${primary.domain}" = {
              serverAliases = [
                "prometheus.${secondary.subdomain}.${secondary.domain}"
              ];
              extraConfig = cloudflare services.prometheus;
            };

            "searx.${primary.subdomain}.${primary.domain}" = {
              serverAliases = [
                "${primary.subdomain}.${primary.domain}"
                "${secondary.domain}"
                "${secondary.subdomain}.${secondary.domain}"
                "searx.${secondary.subdomain}.${secondary.domain}"
              ];
              extraConfig = cloudflare services.searx;
            };

          };
      };

    modules.impermanence.persistedDirectories = with config.services.caddy; [
      logDir
      dataDir
    ];
  };
}
