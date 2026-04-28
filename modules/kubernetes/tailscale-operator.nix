let
  namespace = "tailscale";
  secret-name = "tailscale-operator-oauth";
in
{
  flake.modules.nixos.k3s-tailscale-operator =
    {
      config,
      lib,
      ...
    }:
    {
      options.modules.k3s-tailscale-operator = with lib; {
        enable = mkEnableOption "k3s tailscale-operator oauth";
      };
      config =
        let
          cfg = config.modules.k3s-tailscale-operator;
        in
        lib.mkIf cfg.enable {
          modules.k3s.secrets = [
            {
              inherit namespace;
              name = secret-name;
              dataFromSops = {
                client_id = config.sops.secrets.tailscale_operator_oauth_client_id.path;
                client_secret = config.sops.secrets.tailscale_operator_oauth_client_secret.path;
              };
            }
          ];
        };
    };

  flake.modules.kubernetes.tailscale-operator =
    {
      config,
      lib,
      charts,
      ...
    }:
    {
      options.modules.tailscale-operator = with lib; {
        enable = mkEnableOption "tailscale-operator";
      };

      config =
        let
          cfg = config.modules.tailscale-operator;
        in
        lib.mkIf cfg.enable {
          nixidy.applicationImports = [ ../../generated/tailscale-operator.nix ];

          applications.tailscale-operator = {
            inherit namespace;
            createNamespace = true;

            helm.releases.tailscale-operator = {
              chart = charts.tailscale.tailscale-operator;
              values = {
                oauthSecretVolume.secret.secretName = secret-name;
                # operatorConfig.nodeSelector."kubernetes.io/hostname" = "pi";
              };
            };

            resources = {
              tailnets.default = {
                metadata.name = "default";
                spec.credentials.secretName = secret-name;
              };
            };

          };
        };
    };
}
