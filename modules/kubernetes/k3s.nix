{ self, ... }:

{
  flake.modules.kubernetes.k3s =
    { lib, ... }:
    {
      imports = with self.modules.kubernetes; [
        cert-manager
        descheduler
        gateway
        monitoring
        nginx
        pihole
        searx
        tailscale-operator
      ];

      nixidy = {
        target.rootPath = "./manifests/k3s";
        defaults.helm.transformer = map (
          lib.kube.removeLabels [
            "app.kubernetes.io/version"
            "helm.sh/chart"
          ]
        );
      };

      modules = {
        cert-manager.enable = true;
        descheduler.enable = true;
        gateway.enable = true;
        monitoring.enable = true;
        nginx.enable = true;
        pihole.enable = true;
        searx.enable = true;
        tailscale-operator.enable = true;
      };
    };

  flake.lib.performanceFavoredPodSpec =
    let
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
    labels: {
      affinity = preferPerformanceNodes;
      tolerations = quickNodeFailureTolerations;
      topologySpreadConstraints = [
        {
          maxSkew = 1;
          topologyKey = "kubernetes.io/hostname";
          whenUnsatisfiable = "DoNotSchedule";
          labelSelector.matchLabels = labels;
        }
      ];
    };
}
