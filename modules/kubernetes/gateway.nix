{
  flake.modules.kubernetes.gateway =
    {
      config,
      lib,
      charts,
      ...
    }:
    {
      options.modules.gateway = with lib; {
        enable = mkEnableOption "k3s HTTPS gateway";
      };

      config =
        let
          cfg = config.modules.gateway;
          domain = "k3s.vansleen.dev";
          secretName = "gateway-k3s-vansleen-dev-tls";
        in
        lib.mkIf cfg.enable {
          nixidy.applicationImports = [
            ../../generated/traefik.nix
          ]
          ++ lib.optionals config.modules.cert-manager.enable [ ../../generated/cert-manager.nix ];

          applications.gateway = {
            namespace = "gateway";
            createNamespace = true;

            helm.releases.traefik = {
              chart = charts.traefik.traefik;
              values = {
                providers = {
                  kubernetesCRD.enabled = false;
                  kubernetesIngress.enabled = false;
                  kubernetesGateway.enabled = true;
                };

                gatewayClass = {
                  enabled = true;
                  name = "traefik";
                };

                gateway = {
                  enabled = true;
                  name = "public";
                  listeners = {
                    websecure = {
                      port = 8443;
                      hostname = "*.${domain}";
                      protocol = "HTTPS";
                      namespacePolicy.from = "All";
                      certificateRefs = [
                        { name = secretName; }
                      ];
                    };
                  };
                };

                service = {
                  type = "LoadBalancer";
                  loadBalancerClass = "tailscale";
                  annotations."tailscale.com/hostname" = "gateway";
                };

                ports.web.expose.default = false;
              };
            };

            resources.certificates.gateway-k3s-vansleen-dev.spec = lib.mkIf config.modules.cert-manager.enable {
              inherit secretName;
              dnsNames = [ "*.${domain}" ];
              issuerRef = {
                name = "letsencrypt-cloudflare";
                kind = "ClusterIssuer";
              };
            };
          };
        };
    };
}
