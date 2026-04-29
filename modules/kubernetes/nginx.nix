{ self, ... }:

{
  flake.modules.kubernetes.nginx =
    { config, lib, ... }:
    {
      options.modules.nginx = with lib; {
        enable = mkEnableOption "nginx";
      };

      config =
        let
          cfg = config.modules.nginx;
          podLabels = {
            app = "nginx";
          };
        in
        lib.mkIf cfg.enable {
          nixidy.applicationImports = lib.mkIf config.modules.gateway.enable [ ../../generated/traefik.nix ];

          applications.nginx = {
            namespace = "nginx";
            createNamespace = true;

            resources = {
              httpRoutes.nginx.spec = lib.mkIf config.modules.gateway.enable {
                parentRefs = [
                  {
                    name = "public";
                    namespace = "gateway";
                    sectionName = "websecure";
                  }
                ];
                hostnames = [
                  "nginx.k3s.vansleen.dev"
                  "nginx-test.k3s.vansleen.dev"
                ];
                rules = [
                  {
                    backendRefs = [
                      {
                        name = "nginx";
                        port = 80;
                      }
                    ];
                  }
                ];
              };

              deployments.nginx.spec = {
                replicas = 2;
                strategy.rollingUpdate = {
                  maxSurge = 0;
                  maxUnavailable = 1;
                };
                selector.matchLabels = podLabels;
                template = {
                  metadata.labels = podLabels;
                  spec = (self.lib.performanceFavoredPodSpec podLabels) // {
                    containers.nginx = {
                      image = "nginx:1.25.1";
                      ports.http.containerPort = 80;
                      volumeMounts."/usr/share/nginx/html".name = "html";
                    };
                    volumes.html.configMap.name = "nginx-html";
                  };
                };
              };

              services.nginx.spec = {
                selector = podLabels;
                ports.http.port = 80;
              };

              podDisruptionBudgets.nginx.spec = {
                minAvailable = 1;
                selector.matchLabels = podLabels;
              };

              configMaps.nginx-html.data."index.html" = /* html */ ''
                <!DOCTYPE html>
                <html>
                  <body>
                    <h1>let's change the content</h1>
                  </body>
                </html>
              '';
            };
          };
        };
    };
}
