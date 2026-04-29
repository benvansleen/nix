{ self, ... }:

let
  namespace = "searx";
  secret-name = "searxng-secret";
  hostname = "searx.vansleen.dev";
in
{
  flake.modules.nixos.k3s-searx =
    { config, lib, ... }:
    {
      options.modules.k3s-searx = with lib; {
        enable = mkEnableOption "k3s SearxNG secret";
      };

      config = lib.mkIf config.modules.k3s-searx.enable {
        modules.k3s.secrets = [
          {
            inherit namespace;
            name = secret-name;
            dataFromSops.SEARXNG_SECRET = config.sops.secrets.searx_secretkey.path;
          }
        ];
      };
    };

  flake.modules.kubernetes.searx =
    { config, lib, ... }:
    {
      options.modules.searx = with lib; {
        enable = mkEnableOption "SearxNG";
      };

      config =
        let
          podLabels = {
            app = "searx";
          };
        in
        lib.mkIf config.modules.searx.enable {
          nixidy.applicationImports = lib.mkIf config.modules.gateway.enable [ ../../generated/traefik.nix ];

          applications.searx = {
            inherit namespace;
            createNamespace = true;

            resources = {
              configMaps.searxng-settings.data."settings.yml" = ''
                use_default_settings: true

                server:
                  bind_address: "0.0.0.0"
                  port: 8080
                  secret_key: "$SEARXNG_SECRET"
                  base_url: "https://${hostname}/"

                search:
                  formats:
                    - html
                    - json

                ui:
                  default_locale: "en"
                  query_in_title: false
                  infinite_scroll: true
                  center_alignment: true
                  default_theme: simple
                  theme_args:
                    simple_style: auto
                  hotkeys: vim

                enabled_plugins:
                  - Basic Calculator
                  - Hostnames plugin
                  - Unit converter plugin
                  - Tracker URL remover
              '';

              deployments.searx.spec = {
                replicas = 1;
                selector.matchLabels = podLabels;
                template = {
                  metadata.labels = podLabels;
                  spec = (self.lib.performanceFavoredPodSpec podLabels) // {
                    containers.searx = {
                      image = "searxng/searxng:2026.4.28-ed5955a5c";
                      envFrom = [
                        { secretRef.name = secret-name; }
                      ];
                      ports.http.containerPort = 8080;
                      volumeMounts."/etc/searxng/settings.yml" = {
                        name = "settings";
                        subPath = "settings.yml";
                      };
                    };
                    volumes.settings.configMap.name = "searxng-settings";
                  };
                };
              };

              services.searx.spec = {
                selector = podLabels;
                ports.http = {
                  port = 80;
                  targetPort = "http";
                };
              };

              httpRoutes.searx.spec = lib.mkIf config.modules.gateway.enable {
                parentRefs = [
                  {
                    name = "public";
                    namespace = "gateway";
                    sectionName = "websecure";
                  }
                ];
                hostnames = [ hostname ];
                rules = [
                  {
                    backendRefs = [
                      {
                        name = "searx";
                        port = 80;
                      }
                    ];
                  }
                ];
              };
            };
          };
        };
    };
}
