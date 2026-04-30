{
  flake.modules.kubernetes.descheduler =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      options.modules.descheduler = with lib; {
        enable = mkEnableOption "descheduler";
      };

      config =
        let
          cfg = config.modules.descheduler;
          namespace = "descheduler";
          stuckPodReaperScript = /* bash */ ''
            min_age_seconds="''${MIN_AGE_SECONDS:-120}"
            now="$(date -u +%s)"

            kubectl get pods --all-namespaces \
              -o go-template='{{range .items}}{{if .metadata.deletionTimestamp}}{{.metadata.namespace}} {{.metadata.name}} {{.spec.nodeName}} {{.metadata.deletionTimestamp}}{{"\n"}}{{end}}{{end}}' |
              while read -r pod_namespace pod_name node_name deletion_timestamp; do
                [ -n "$pod_namespace" ] || continue
                [ -n "$node_name" ] || continue

                node_ready="$(kubectl get node "$node_name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
                [ "$node_ready" != "True" ] || continue

                deletion_epoch="$(date -u -d "$deletion_timestamp" +%s)"
                age_seconds="$((now - deletion_epoch))"
                [ "$age_seconds" -ge "$min_age_seconds" ] || continue

                kubectl delete pod -n "$pod_namespace" "$pod_name" --grace-period=0 --force --wait=false
              done
          '';
          chart =
            pkgs.fetchFromGitHub {
              owner = "kubernetes-sigs";
              repo = "descheduler";
              rev = "descheduler-helm-chart-0.35.1";
              hash = "sha256-dLNr1lqiAvtcLJvNDLj7kLutQ8cZiJnVfFaSZFm4+Zk=";
            }
            + "/charts/descheduler";
        in
        lib.mkIf cfg.enable {
          applications.descheduler = {
            inherit namespace;
            createNamespace = true;

            helm.releases.descheduler = {
              inherit chart;
              values = {
                kind = "CronJob";
                schedule = "*/5 * * * *";
                priorityClassName = "";
                deschedulerPolicy.profiles = [
                  {
                    name = "default";
                    pluginConfig = [
                      {
                        name = "DefaultEvictor";
                        args = {
                          evictSystemCriticalPods = false;
                          podProtections.defaultDisabled = [ "PodsWithLocalStorage" ];
                        };
                      }
                      {
                        name = "RemovePodsViolatingNodeAffinity";
                        args.nodeAffinityType = [ "preferredDuringSchedulingIgnoredDuringExecution" ];
                      }
                      { name = "RemovePodsViolatingTopologySpreadConstraint"; }
                    ];
                    plugins = {
                      balance.enabled = [ "RemovePodsViolatingTopologySpreadConstraint" ];
                      deschedule.enabled = [ "RemovePodsViolatingNodeAffinity" ];
                    };
                  }
                ];
                resources = {
                  requests = {
                    cpu = "50m";
                    memory = "64Mi";
                  };
                  limits = {
                    cpu = "200m";
                    memory = "128Mi";
                  };
                };
              };
            };

            resources = {
              serviceAccounts.stuck-pod-reaper = { };

              clusterRoles.stuck-pod-reaper.rules = [
                {
                  apiGroups = [ "" ];
                  resources = [ "pods" ];
                  verbs = [
                    "get"
                    "list"
                    "delete"
                  ];
                }
                {
                  apiGroups = [ "" ];
                  resources = [ "nodes" ];
                  verbs = [
                    "get"
                    "list"
                  ];
                }
              ];

              clusterRoleBindings.stuck-pod-reaper = {
                roleRef = {
                  apiGroup = "rbac.authorization.k8s.io";
                  kind = "ClusterRole";
                  name = "stuck-pod-reaper";
                };
                subjects = [
                  {
                    kind = "ServiceAccount";
                    name = "stuck-pod-reaper";
                    inherit namespace;
                  }
                ];
              };

              cronJobs.stuck-pod-reaper.spec = {
                schedule = "* * * * *";
                concurrencyPolicy = "Forbid";
                successfulJobsHistoryLimit = 1;
                failedJobsHistoryLimit = 3;
                jobTemplate.spec = {
                  backoffLimit = 0;
                  template.spec = {
                    serviceAccountName = "stuck-pod-reaper";
                    restartPolicy = "Never";
                    nodeSelector."kubernetes.io/hostname" = "pi";
                    containers.stuck-pod-reaper = {
                      image = "bitnami/kubectl:latest";
                      command = [
                        "/bin/bash"
                        "-ceu"
                      ];
                      args = [ stuckPodReaperScript ];
                      env.MIN_AGE_SECONDS.value = "120";
                      resources = {
                        requests = {
                          cpu = "10m";
                          memory = "32Mi";
                        };
                        limits = {
                          cpu = "100m";
                          memory = "128Mi";
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
    };

}
