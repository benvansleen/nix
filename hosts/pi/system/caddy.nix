{
  config,
  pkgs-stable,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.caddy;

  # Build currently breaks w/ caddy-v2.9.0
  # https://github.com/tailscale/caddy-tailscale/pull/83
  my-caddy = pkgs-stable.caddy.withPlugins {
    plugins = [
      "github.com/tailscale/caddy-tailscale@f21c01b660c896bdd6bacc37178dc00d9af282b4"
      "github.com/caddy-dns/cloudflare@89f16b99c18ef49c8bb470a82f895bce01cbaece"
    ];
    hash = "sha256-KCOjtpWe8vw/vMFx56KcM12owBzWnkCwkNiwNc/adAs=";
  };
in
{
  options.modules.caddy.enable = mkEnableOption "caddy";

  config = mkIf cfg.enable {
    environment.systemPackages = [ my-caddy ];
    sops.templates."caddy.env".content = ''
      TS_AUTHKEY=${config.sops.placeholder.tailscale_sidecar_authkey}
      CLOUDFLARE_TOKEN=${config.sops.placeholder.cloudflare_caddy_api_token}
    '';
    services.caddy =
      let
        services = {
          searx = ''
            encode zstd gzip
            reverse_proxy pi:${toString config.modules.searx.port}
          '';
          pihole = ''
            encode zstd gzip
            redir / /admin{uri}
            reverse_proxy pi:${toString config.modules.pihole.web-ui-port}
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
      {
        enable = true;
        enableReload = false;
        package = my-caddy;
        inherit (lib.constants) email;
        dataDir = "/var/lib/caddy";
        logDir = "/var/log/caddy";

        environmentFile = config.sops.templates."caddy.env".path;
        globalConfig = ''
          tailscale {
            auth_key {$TS_AUTHKEY}
            webui true
          }
        '';
        extraConfig =
          ''
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
        virtualHosts = {
          "searx.ben.vansleen.dev" = {
            serverAliases = [
              "ben.vansleen.dev"
              "benvansleen.dev"
              "net.benvansleen.dev"
              "searx.net.benvansleen.dev"
            ];
            extraConfig = cloudflare services.searx;
          };

          "pihole.ben.vansleen.dev" = {
            serverAliases = [
              "pihole.net.benvansleen.dev"
            ];
            extraConfig = cloudflare services.pihole;
          };
        };
      };

    modules.impermanence.persistedDirectories = with config.services.caddy; [
      logDir
      dataDir
    ];
  };
}
