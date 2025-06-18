{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.unbound;
in
{
  options.modules.unbound = {
    enable = mkEnableOption "unbound";
    port = mkOption {
      type = types.port;
      default = 53;
    };
    num-threads = mkOption {
      type = types.int;
      default = 1;
    };
    prometheusPort = mkOption {
      type = types.port;
      default = 9153;
    };
  };

  config = mkIf cfg.enable {
    services = {

      # CANNOT RESOLVE DNS REQUESTS WHEN BEHIND MULLVAD VPN
      unbound = {
        enable = true;
        checkconf = false;
        enableRootTrustAnchor = true;
        resolveLocalQueries = true;
        stateDir = "/var/lib/unbound";
        settings = {
          # forward-zone = {
          #   # name = "clouded-mimosa.ts.net.";
          #   forward-addr = [
          #     "100.100.100.100"
          #   ];
          #   forward-first = true;
          # };

          server = {
            inherit (cfg) port num-threads;
            verbosity = 2;
            log-queries = true;
            log-replies = true;
            log-servfail = true;
            qname-minimisation = true;
            edns-buffer-size = 1232;

            interface = [
              "0.0.0.0"
              "::0"
              "10.88.0.1"
            ];
            access-control = [
              "0.0.0.0/0 allow" # Allow anyone to make DNS requests
            ];
            extended-statistics = true;

            # Performance settings
            prefetch = true;
            cache-min-ttl = 3600;
            msg-cache-slabs = cfg.num-threads;
            rrset-cache-slabs = cfg.num-threads;
            infra-cache-slabs = cfg.num-threads;
            key-cache-slabs = cfg.num-threads;

            rrset-cache-size = "256m";
            msg-cache-size = "128m";

            outgoing-range = (1024 / cfg.num-threads) - 50;

            so-rcvbuf = "4m";
            so-sndbuf = "4m";
            so-reuseport = true;
          };
          remote-control = {
            control-enable = true;
            control-interface = "127.0.0.1";
            control-port = toString (cfg.port + 1);
          };
        };
      };
      prometheus.exporters.unbound = {
        enable = true;
        port = cfg.prometheusPort;
        unbound = {
          host = "tcp://${config.services.unbound.settings.remote-control.control-interface}:${config.services.unbound.settings.remote-control.control-port}";
        };
      };
    };
  };
}
