{
  flake.modules.nixos = {
    k3s =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        options.modules.k3s = with lib; {
          users = mkOption {
            type = with types; listOf str;
            default = [ ];
            description = "Users that should receive a copy of the k3s kubeconfig.";
          };
          primary = mkOption {
            type = with types; nullOr str;
            default = null;
            description = "hostname for primary k3s server node";
          };
          useTailscale = mkOption {
            type = types.bool;
            default = true;
            description = "Use the node's runtime Tailscale IP for k3s node traffic.";
          };
        };

        config =
          let
            cfg = config.modules.k3s;
          in
          {
            services.k3s = {
              tokenFile = config.sops.secrets.k3s_token.path;
              extraFlags = lib.optionals cfg.useTailscale [
                "--node-ip=\${K3S_TAILSCALE_IP}"
                "--node-external-ip=\${K3S_TAILSCALE_IP}"
                "--flannel-iface=tailscale0"
              ];
            };

            systemd = {
              services = {
                k3s = lib.mkIf (config.services.k3s.enable && cfg.useTailscale) {
                  after = [
                    "tailscaled.service"
                    "tailscale-autoconnect.service"
                  ];
                  wants = [
                    "tailscaled.service"
                    "tailscale-autoconnect.service"
                  ];
                  path = [ config.services.k3s.package.passthru.k3sBundle ];
                  serviceConfig.EnvironmentFile = lib.mkForce [ "-/run/k3s/tailscale.env" ];
                  preStart = ''
                    install -d -m 0755 /run/k3s

                    for attempt in $(seq 1 30); do
                      tailscale_ip="$(${lib.getExe pkgs.tailscale} ip -4 2>/dev/null || true)"
                      if [ -n "$tailscale_ip" ]; then
                        break
                      fi
                      sleep 1
                    done

                    if [ -z "$tailscale_ip" ]; then
                      echo "failed to determine Tailscale IPv4 address" >&2
                      exit 1
                    fi

                    printf 'K3S_TAILSCALE_IP=%s\n' "$tailscale_ip" > /run/k3s/tailscale.env
                  '';
                };

                k3s-tailscale-routes = {
                  description = "Keep k3s pod and service CIDRs out of Tailscale exit-node routing";
                  after = [
                    "tailscaled.service"
                    "k3s.service"
                  ];
                  wants = [ "tailscaled.service" ];
                  wantedBy = [ "multi-user.target" ];

                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                  };

                  path = [ pkgs.iproute2 ];

                  script = ''
                    for attempt in $(seq 1 30); do
                      if ip -4 addr show cni0 >/dev/null 2>&1; then
                        break
                      fi
                      sleep 1
                    done

                    if ip -4 addr show cni0 >/dev/null 2>&1; then
                      pod_ip_cidr="$(ip -4 -o addr show cni0 | while read -r _ _ _ cidr _; do printf '%s\n' "$cidr"; break; done)"
                      pod_cidr="''${pod_ip_cidr%.1/24}.0/24"
                      ip route replace throw "$pod_cidr" table 52
                    fi

                    ip route replace throw 10.42.0.0/16 table 52
                    ip route replace throw 10.43.0.0/16 table 52
                  '';
                };

                copy-kubeconfig = lib.mkIf (config.services.k3s.enable && config.services.k3s.role == "server") {
                  description = "Copy k3s kubeconfig to configured users";
                  wantedBy = [ "multi-user.target" ];

                  unitConfig.ConditionPathExists = "/etc/rancher/k3s/k3s.yaml";

                  serviceConfig = {
                    Type = "oneshot";
                  };

                  script =
                    let
                      install = lib.getExe' pkgs.coreutils "install";
                      copyForUser =
                        user:
                        let
                          inherit (config.users.users.${user}) home;
                        in
                        /* sh */ ''
                          ${install} -d -m 0700 -o ${lib.escapeShellArg user} -g users ${lib.escapeShellArg home}/.kube
                          ${install} -m 0600 -o ${lib.escapeShellArg user} -g users /etc/rancher/k3s/k3s.yaml ${lib.escapeShellArg home}/.kube/config
                        '';
                    in
                    /* sh */ ''
                      ${lib.concatMapStringsSep "\n" copyForUser config.modules.k3s.users}
                    '';
                };
              };

              paths.copy-kubeconfig =
                lib.mkIf (config.services.k3s.enable && config.services.k3s.role == "server")
                  {
                    wantedBy = [ "multi-user.target" ];
                    pathConfig = {
                      PathChanged = "/etc/rancher/k3s/k3s.yaml";
                      Unit = "copy-kubeconfig.service";
                    };
                  };
            };

            environment.systemPackages = with pkgs; [
              k9s
              kubectl
            ];

            networking.firewall = {
              extraInputRules = ''
                ip saddr 10.42.0.0/16 accept
              '';
              trustedInterfaces = [
                "cni0"
                "flannel.1"
              ];
            };

            persist.directories = [
              "/var/lib/rancher/k3s"
              "/etc/rancher"
            ]
            ++ (map (user: "${config.users.users.${user}.home}/.kube") cfg.users);
          };
      };

    "k3s/server" =
      { config, lib, ... }:
      let
        cfg = config.modules.k3s;
      in
      {
        config = {
          services.k3s = {
            enable = true;
            role = "server";
            extraFlags = [
              "--disable=traefik"
              "--disable=servicelb"
              "--disable=local-storage"
              "--disable=metrics-server"
            ]
            ++ lib.optionals cfg.useTailscale [
              "--advertise-address=\${K3S_TAILSCALE_IP}"
              "--tls-san=\${K3S_TAILSCALE_IP}"
            ];
          }
          // (
            if (config.machine.name == cfg.primary) then
              {
                clusterInit = true;
              }
            else
              {
                serverAddr = "https://${cfg.primary}:6443";
              }
          );
        };
      };

    "k3s/agent" =
      { config, ... }:
      let
        cfg = config.modules.k3s;
      in
      {
        ## one-time from agent nodes:
        ## mkdir -p ~/.kube
        ## scp <cfg.primary>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
        ## chmod 600 ~/.kube/config
        ## kubectl config set-cluster default --server=https://pi:6443
        config = {
          services.k3s = {
            enable = true;
            role = "agent";
            serverAddr = "https://${cfg.primary}:6443";
          };
        };
      };
  };
}
