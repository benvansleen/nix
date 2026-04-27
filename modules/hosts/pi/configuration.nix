{
  flake.modules.nixos.pi-configuration =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      if-using-sops = lib.mkIf (builtins.hasAttr "sops" config);
    in
    {
      config = {
        modules = {
          clonix = {
            enable = true;
            deployments = [
              rec {
                deploymentName = "backup-${config.machine.name}";
                local = {
                  dir = "/";
                  exclude = [
                    "/bin"
                    "/boot"
                    "/dev"
                    "/lib"
                    "/mnt"
                    "/nix"
                    "/proc"
                    "/run"
                    "/sys"
                    "/usr"
                  ];
                };
                targetDir = "${lib.constants.backup-path}/${deploymentName}";
                remote.enable = false;
                should-propagate-file-deletion = true;
                timer = {
                  enable = true;
                  OnCalendar = "hourly";
                  Persistent = true;
                };
              }
            ];
          };
          containers = {
            disable-podman-dns = true;
          };
          grafana.enable = true;
          maybe.enable = true;
          pihole.enable = true;
          prometheus = {
            server = {
              scrapeConfigs = [
                {
                  job_name = "home";
                  static_configs = [
                    {
                      targets = [
                        # TODO: fix when moving to colmena
                        "pi:${toString config.modules.prometheus.client.port}"
                        "desktop:${toString config.modules.prometheus.client.port}"
                        "laptop:${toString config.modules.prometheus.client.port}"
                      ];
                    }
                  ];
                  scrape_interval = "15s";
                }
                {
                  job_name = "dns";
                  static_configs = [
                    {
                      targets = [
                        # TODO: fix when moving to colmena
                        "pi:${toString config.modules.unbound.prometheusPort}"
                      ];
                    }
                  ];
                  scrape_interval = "15s";
                }
                {
                  # https://github.com/Malfhas/caddy-grafana
                  job_name = "caddy";
                  static_configs = [
                    {
                      targets = [
                        # TODO: fix when moving to colmena
                        "pi:${toString config.modules.caddy.admin-port}"
                      ];
                    }
                  ];
                  scrape_interval = "15s";
                }
                {
                  job_name = "pihole";
                  static_configs = [
                    {
                      targets = [
                        "pi:${toString config.modules.pihole.prometheus-exporter-port}"
                      ];
                    }
                  ];
                  scrape_interval = "15s";
                }
              ];
            };
          };
          searx = {
            port = 8888;
          };
          tailscale = {
            authKeyFile = if-using-sops config.sops.secrets.tailscale_authkey.path;
            tailscale-up-extra-args = [
              "--ssh"
              "--accept-risk=lose-ssh"
              "--exit-node=auto:any"
              "--advertise-routes=192.168.1.0/24"
            ];
          };
          unbound = {
            enable = true;
            port = 5335;
            num-threads = 4;
          };
        };

        environment.systemPackages = with pkgs; [
          dig
        ];

        services.openssh.enable = true;
        networking.wireless.enable = false;

        system.stateVersion = "23.11";
      };
    };
}
