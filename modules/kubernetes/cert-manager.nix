{ inputs, ... }:

let
  namespace = "cert-manager";
  cloudflare-secret-name = "cloudflare-api-token";
in
{
  flake.modules.nixos.k3s-cert-manager =
    {
      config,
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
          modules.k3s.secrets = [
            {
              inherit namespace;
              name = cloudflare-secret-name;
              dataFromSops.api-token = config.sops.secrets.cloudflare_caddy_api_token.path;
            }
          ];
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
          nixidy.applicationImports = [ ../../generated/cert-manager.nix ];

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

            resources.clusterIssuers.letsencrypt-cloudflare.spec.acme = {
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
          };
        };
    };
}
