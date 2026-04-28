{ inputs, ... }:

let
  namespace = "cert-manager";
  cloudflare-secret-name = "cloudflare-api-token";
in
{
  flake.modules.nixos.k3s-cert-manager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.modules.k3s-cert-manager = with lib; {
        enable = mkEnableOption "k3s cert-manager Cloudflare token secret";
      };

      config =
        let
          cfg = config.modules.k3s-cert-manager;
        in
        lib.mkIf cfg.enable {
          systemd.services.cert-manager-cloudflare-secret = {
            wantedBy = [ "multi-user.target" ];
            after = [ "k3s.service" ];
            requires = [ "k3s.service" ];
            environment.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
            serviceConfig = {
              Type = "oneshot";
              TimeoutStartSec = "2min";
            };

            script = /* sh */ ''
              for attempt in $(seq 1 60); do
                if ${pkgs.kubectl}/bin/kubectl get --raw=/readyz >/dev/null; then
                  break
                fi

                if [ "$attempt" -eq 60 ]; then
                  exit 1
                fi

                sleep 2
              done

              ${pkgs.kubectl}/bin/kubectl create namespace ${namespace} \
                --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply --validate=false -f -

              ${pkgs.kubectl}/bin/kubectl -n ${namespace} create secret generic ${cloudflare-secret-name} \
                --from-literal=api-token="$(cat ${config.sops.secrets.cloudflare_caddy_api_token.path})" \
                --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply --validate=false -f -
            '';
          };
        };
    };

  flake.modules.kubernetes.cert-manager =
    {
      config,
      lib,
      charts,
      ...
    }:
    {
      options.modules.cert-manager = with lib; {
        enable = mkEnableOption "cert-manager";
      };

      config =
        let
          cfg = config.modules.cert-manager;
          ignoreWebhookFailure =
            object:
            if
              builtins.elem object.kind [
                "MutatingWebhookConfiguration"
                "ValidatingWebhookConfiguration"
              ]
              && object.metadata.name == "cert-manager-webhook"
            then
              object
              // {
                webhooks = map (webhook: webhook // { failurePolicy = "Ignore"; }) object.webhooks;
              }
            else
              object;
        in
        lib.mkIf cfg.enable {
          applications.cert-manager = {
            inherit namespace;
            createNamespace = true;

            helm.releases.cert-manager = {
              chart = charts.jetstack.cert-manager;
              values = {
                crds.enabled = true;
                dns01RecursiveNameservers = "1.1.1.1:53,8.8.8.8:53";
                dns01RecursiveNameserversOnly = true;
              };
              transformer = map ignoreWebhookFailure;
            };

            objects = [
              {
                apiVersion = "cert-manager.io/v1";
                kind = "ClusterIssuer";
                metadata.name = "letsencrypt-cloudflare";
                spec.acme = {
                  inherit (inputs.secrets.personal-info) email;
                  server = "https://acme-v02.api.letsencrypt.org/directory";
                  privateKeySecretRef.name = "letsencrypt-cloudflare-account-key";
                  solvers = [
                    {
                      dns01.cloudflare.apiTokenSecretRef = {
                        name = cloudflare-secret-name;
                        key = "api-token";
                      };
                    }
                  ];
                };
              }
            ];
          };
        };
    };
}
