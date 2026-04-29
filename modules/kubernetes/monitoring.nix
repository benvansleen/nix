{ self, ... }:

let
  namespace = "monitoring";
  prometheusLabels = {
    app = "prometheus";
  };
  grafanaLabels = {
    app = "grafana";
  };
in
{
  flake.modules.kubernetes.monitoring =
    { config, lib, ... }:
    {
      options.modules.monitoring = with lib; {
        enable = mkEnableOption "Grafana and Prometheus";
        nodeExporterPort = mkOption {
          type = types.port;
          default = 9002;
          description = "Port used by host-level Prometheus node exporters.";
        };
      };

      config =
        let
          cfg = config.modules.monitoring;
        in
        lib.mkIf cfg.enable {
          nixidy.applicationImports = lib.mkIf config.modules.gateway.enable [ ../../generated/traefik.nix ];

          applications.monitoring = {
            inherit namespace;
            createNamespace = true;

            resources = {
              serviceAccounts.prometheus = { };

              clusterRoles.prometheus.rules = [
                {
                  apiGroups = [ "" ];
                  resources = [ "nodes" ];
                  verbs = [
                    "get"
                    "list"
                    "watch"
                  ];
                }
              ];

              clusterRoleBindings.prometheus = {
                roleRef = {
                  apiGroup = "rbac.authorization.k8s.io";
                  kind = "ClusterRole";
                  name = "prometheus";
                };
                subjects = [
                  {
                    kind = "ServiceAccount";
                    name = "prometheus";
                    inherit namespace;
                  }
                ];
              };

              configMaps.prometheus.data."prometheus.yml" = ''
                global:
                  scrape_interval: 15s

                scrape_configs:
                  - job_name: prometheus
                    static_configs:
                      - targets:
                          - localhost:9090

                  - job_name: node-exporter
                    kubernetes_sd_configs:
                      - role: node
                    relabel_configs:
                      - source_labels: [__meta_kubernetes_node_address_InternalIP]
                        regex: (.+)
                        target_label: __address__
                        replacement: $1:${toString cfg.nodeExporterPort}
                      - source_labels: [__meta_kubernetes_node_name]
                        target_label: instance
                      - action: labelmap
                        regex: __meta_kubernetes_node_label_(.+)

                  - job_name: traefik
                    static_configs:
                      - targets:
                          - traefik-metrics.gateway.svc.cluster.local:9100

                  - job_name: unbound
                    static_configs:
                      - targets:
                          - pihole-unbound-metrics.dns.svc.cluster.local:9167
              '';

              configMaps = {
                grafana-datasources.data."datasources.yml" = ''
                  apiVersion: 1

                  datasources:
                    - name: Prometheus
                      type: prometheus
                      access: proxy
                      url: http://prometheus:9090
                      isDefault: true
                '';
                grafana-config = {
                  metadata.name = "grafana-config";
                  data."grafana.ini" = ''
                    [auth]
                    disable_login_form = true
                    disable_signout_menu = true

                    [auth.anonymous]
                    enabled = true
                    org_role = Admin
                  '';
                };
              };

              deployments.prometheus.spec = {
                replicas = 1;
                selector.matchLabels = prometheusLabels;
                template = {
                  metadata.labels = prometheusLabels;
                  spec = (self.lib.performanceFavoredPodSpec prometheusLabels) // {
                    serviceAccountName = "prometheus";
                    containers.prometheus = {
                      image = "prom/prometheus:v2.55.1";
                      args = [
                        "--config.file=/etc/prometheus/prometheus.yml"
                        "--storage.tsdb.path=/prometheus"
                        "--storage.tsdb.retention.time=30d"
                        "--web.enable-lifecycle"
                      ];
                      ports.http.containerPort = 9090;
                      volumeMounts = {
                        "/etc/prometheus/prometheus.yml" = {
                          name = "config";
                          subPath = "prometheus.yml";
                        };
                        "/prometheus".name = "data";
                      };
                    };
                    volumes = {
                      config.configMap.name = "prometheus";
                      data.persistentVolumeClaim.claimName = "prometheus-data";
                    };
                  };
                };
              };

              deployments.grafana.spec = {
                replicas = 1;
                selector.matchLabels = grafanaLabels;
                template = {
                  metadata.labels = grafanaLabels;
                  spec = (self.lib.performanceFavoredPodSpec grafanaLabels) // {
                    containers.grafana = {
                      image = "grafana/grafana:11.5.2";
                      ports.http.containerPort = 3000;
                      volumeMounts = {
                        "/etc/grafana/provisioning/datasources".name = "datasources";
                        "/etc/grafana/grafana.ini" = {
                          name = "grafana-config";
                          subPath = "grafana.ini";
                        };
                        "/var/lib/grafana".name = "data";
                      };
                    };
                    volumes = {
                      datasources.configMap.name = "grafana-datasources";
                      grafana-config.configMap.name = "grafana-config";
                      data.persistentVolumeClaim.claimName = "grafana-data";
                    };
                  };
                };
              };

              persistentVolumeClaims = {
                grafana-data = {
                  metadata.name = "grafana-data";
                  spec = {
                    accessModes = [ "ReadWriteOnce" ];
                    storageClassName = "local-path";
                    resources.requests.storage = "1Gi";
                  };
                };
                prometheus-data = {
                  metadata.name = "prometheus-data";
                  spec = {
                    accessModes = [ "ReadWriteOnce" ];
                    storageClassName = "local-path";
                    resources.requests.storage = "1Gi";
                  };
                };
              };

              services.prometheus.spec = {
                selector = prometheusLabels;
                ports.http = {
                  port = 9090;
                  targetPort = "http";
                };
              };

              services.grafana.spec = {
                selector = grafanaLabels;
                ports.http = {
                  port = 3000;
                  targetPort = "http";
                };
              };

              httpRoutes.prometheus.spec = lib.mkIf config.modules.gateway.enable {
                parentRefs = [
                  {
                    name = "public";
                    namespace = "gateway";
                    sectionName = "websecure";
                  }
                ];
                hostnames = [
                  "prometheus.vansleen.dev"
                ];
                rules = [
                  {
                    backendRefs = [
                      {
                        name = "prometheus";
                        port = 9090;
                      }
                    ];
                  }
                ];
              };

              httpRoutes.grafana.spec = lib.mkIf config.modules.gateway.enable {
                parentRefs = [
                  {
                    name = "public";
                    namespace = "gateway";
                    sectionName = "websecure";
                  }
                ];
                hostnames = [
                  "grafana.vansleen.dev"
                ];
                rules = [
                  {
                    backendRefs = [
                      {
                        name = "grafana";
                        port = 3000;
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
