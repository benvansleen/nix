{
  config,
  pkgs,
  lib,
  ...
}:

let
  if-using-sops = lib.mkIf config.modules.sops.enable;
in
lib.importAll ./.
// {
  config = {
    modules = {
      caddy.enable = true;
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
        enable = true;
        disable-podman-dns = true;
      };
      display-manager.enable = false;
      firefox.enable = false;
      fonts.enable = false;
      grafana.enable = true;
      home-manager.enable = true;
      impermanence.enable = false;
      maybe.enable = true;
      pihole.enable = true;
      prometheus = {
        client.enable = true;
        server = {
          enable = true;
          scrapeConfigs = [
            {
              job_name = "home";
              static_configs = [
                {
                  targets = [
                    # TODO: fix when moving to colmena
                    "pi:${toString config.modules.prometheus.client.port}"
                    "amd:${toString config.modules.prometheus.client.port}"
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
          ];
        };
      };
      searx = {
        enable = true;
        port = 8888;
      };
      sops.enable = true;
      stylix.enable = false;
      tailscale = {
        enable = true;
        authKeyFile = if-using-sops config.sops.secrets.tailscale_authkey.path;
        tailscale-up-extra-args = [
          "--ssh"
          "--exit-node=us-qas-wg-101.mullvad.ts.net." # Ashburn, VA
          "--exit-node-allow-lan-access" # Necessary for pihole DNS
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
}
