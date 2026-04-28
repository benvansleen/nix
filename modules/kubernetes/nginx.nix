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
          quickNodeFailureTolerations = [
            {
              key = "node.kubernetes.io/not-ready";
              operator = "Exists";
              effect = "NoExecute";
              tolerationSeconds = 30;
            }
            {
              key = "node.kubernetes.io/unreachable";
              operator = "Exists";
              effect = "NoExecute";
              tolerationSeconds = 30;
            }
          ];
          preferPerformanceNodes = {
            nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100;
                preference.matchExpressions = [
                  {
                    key = "node.vansleen.dev/tier";
                    operator = "In";
                    values = [ "performance" ];
                  }
                ];
              }
            ];
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
                selector.matchLabels.app = "nginx";
                template = {
                  metadata.labels.app = "nginx";
                  spec = {
                    affinity = preferPerformanceNodes;
                    tolerations = quickNodeFailureTolerations;
                    topologySpreadConstraints = [
                      {
                        maxSkew = 1;
                        topologyKey = "kubernetes.io/hostname";
                        whenUnsatisfiable = "DoNotSchedule";
                        labelSelector.matchLabels.app = "nginx";
                      }
                    ];
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
                selector.app = "nginx";
                ports.http.port = 80;
              };

              podDisruptionBudgets.nginx.spec = {
                minAvailable = 1;
                selector.matchLabels.app = "nginx";
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
