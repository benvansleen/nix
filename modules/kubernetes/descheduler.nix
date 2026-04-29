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
          };
        };
    };

}
