{ self, ... }:

{
  flake.modules.nixos.caddy =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.modules.caddy = with lib; {
        admin-port = mkOption {
          type = types.port;
          default = 2019;
          description = "port where caddy admin information is available";
        };
      };

      config =
        let
          cfg = config.modules.caddy;
        in
        {
          sops.templates."caddy.env".content = ''
            TS_AUTHKEY=${config.sops.placeholder.tailscale_sidecar_authkey}
            CLOUDFLARE_TOKEN=${config.sops.placeholder.cloudflare_caddy_api_token}
          '';
          services.caddy =
            let
              services = {
                grafana = /* caddy */ ''
                  tailscale_auth
                  encode zstd gzip
                  reverse_proxy pi:${toString config.modules.grafana.port} {
                    header_up X-Webauth-User {http.auth.user.tailscale_user}
                  }
                '';
                maybe = /* caddy */ ''
                  encode zstd gzip
                  reverse_proxy pi:${toString config.modules.maybe.port}
                '';
                pihole = /* caddy */ ''
                  encode zstd gzip
                  redir / /admin{uri}
                  reverse_proxy pi:${toString config.modules.pihole.web-ui-port}
                '';
                prometheus = /* caddy */ ''
                  encode zstd gzip
                  reverse_proxy pi:${toString config.modules.prometheus.server.port}
                '';
                searx = /* caddy */ ''
                  encode zstd gzip
                  reverse_proxy pi:${toString config.modules.searx.port}
                '';
              };

              tailscale = host: config: /* caddy */ ''
                :443 {
                  bind tailscale/${host}
                  tls {
                    get_certificate tailscale
                  }
                  ${config}
                }
              '';
              cloudflare = config: /* caddy */ ''
                import cloudflare
                ${config}
              '';
            in
            rec {
              enable = true;
              enableReload = false;
              package = pkgs.local.caddy.withPlugins {
                plugins = [
                  "github.com/tailscale/caddy-tailscale@bb080c4414acd465d8be93b4d8f907dbb2ab2544" # jan 6, 2026
                  "github.com/caddy-dns/cloudflare@2fc25ee62f40fe21b240f83ab2fb6e2be6dbb953" # oct 22, 2025
                ];
                hash = "sha256-ldAPh2Mqh1xIE+KVPiQpyOxXnaAuDbUPI2SACTdtYN0=";
                doInstallCheck = false;
              };
              inherit (self.constants) email;
              dataDir = "/var/lib/caddy";
              logDir = "/var/log/caddy";

              environmentFile = config.sops.templates."caddy.env".path;
              logFormat = /* caddy */ ''
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
              globalConfig = /* caddy */ ''
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
              extraConfig =
                /* caddy */ ''
                  https:// {
                    tls {
                      on_demand
                    }
                  }

                  (cloudflare) {
                    tls {
                      dns cloudflare {$CLOUDFLARE_TOKEN}
                      resolvers 8.8.8.8 8.8.4.4
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
                  "grafana.${primary.subdomain}.${primary.domain}" = lib.optionalAttrs config.modules.grafana.enable {
                    serverAliases = [
                      "grafana.${secondary.subdomain}.${secondary.domain}"
                    ];
                    extraConfig = cloudflare ''
                      redir / https://grafana.${self.constants.tailscale-domain}
                    '';
                  };

                  "maybe.${primary.subdomain}.${primary.domain}" = lib.optionalAttrs config.modules.maybe.enable {
                    serverAliases = [
                      "maybe.${primary.domain}"
                      "maybe.${secondary.subdomain}.${secondary.domain}"
                    ];
                    extraConfig = cloudflare services.maybe;
                  };

                  "pihole.${primary.subdomain}.${primary.domain}" = lib.optionalAttrs config.modules.pihole.enable {
                    serverAliases = [
                      "pihole.${secondary.subdomain}.${secondary.domain}"
                    ];
                    extraConfig = cloudflare services.pihole;
                  };

                  "prometheus.${primary.subdomain}.${primary.domain}" =
                    lib.optionalAttrs config.services.prometheus.enable
                      {
                        serverAliases = [
                          "prometheus.${secondary.subdomain}.${secondary.domain}"
                        ];
                        extraConfig = cloudflare services.prometheus;
                      };

                  "searx.${primary.subdomain}.${primary.domain}" = lib.optionalAttrs config.services.searx.enable {
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

          persist.directories = with config.services.caddy; [
            logDir
            dataDir
          ];
        };
    };
}
