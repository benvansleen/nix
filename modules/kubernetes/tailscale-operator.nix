let
  namespace = "tailscale";
  secret-name = "tailscale-operator-oauth";
in
{
  flake.modules.nixos.k3s-tailscale-operator =
    {
      config,
      pkgs,
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
          systemd.services.tailscale-operator-oauth-secret = {
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

              ${pkgs.kubectl}/bin/kubectl -n ${namespace} create secret generic ${secret-name} \
                --from-literal=client_id="$(cat ${config.sops.secrets.tailscale_operator_oauth_client_id.path})" \
                --from-literal=client_secret="$(cat ${config.sops.secrets.tailscale_operator_oauth_client_secret.path})" \
                --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply --validate=false -f -
            '';
          };
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
