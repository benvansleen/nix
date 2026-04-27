{
  flake.modules.nixos."prometheus/client" =
    { config, lib, ... }:
    {
      options.modules.prometheus.client = with lib; {
        enable = mkEnableOption "prometheus/client";
        port = mkOption {
          type = types.port;
          default = 9002;
          description = "DO NOT CHANGE until `colmena` refactor!";
        };
      };

      config =
        let
          cfg = config.modules.prometheus.client;
        in
        lib.mkIf cfg.enable {
          services.prometheus.exporters = {
            node = {
              enable = true;
              enabledCollectors = [
                "conntrack"
                "diskstats"
                "entropy"
                "filefd"
                "filesystem"
                "interrupts"
                "ksmd"
                "loadavg"
                "logind"
                "mdadm"
                "meminfo"
                "netdev"
                "netstat"
                "processes"
                "stat"
                "systemd"
                "tcpstat"
                "time"
                "vmstat"

                "textfile"
              ];
              inherit (cfg) port;
              extraFlags = [
                "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files"
              ];
            };
          };

          # Idea from: https://grahamc.com/blog/nixos-system-version-prometheus/
          system.activationScripts.node-exporter-system-version = ''
            mkdir -p /var/lib/prometheus-node-exporter-text-files
            (
              cd /var/lib/prometheus-node-exporter-text-files
              (
                echo -n "nixos_system_generation ";
                readlink /nix/var/nix/profiles/system | cut -d- -f2
              ) > system-version.prom.next
              mv system-version.prom.next system-version.prom
            )
          '';

          persist.directories = [
            "/var/lib/prometheus-node-exporter-text-files"
          ];
        };
    };
}
