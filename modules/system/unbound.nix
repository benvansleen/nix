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
    modules.tailscale.tailscale-up-extra-args = [
      "--exit-node-allow-lan-access"
    ];

    services = {

      # CANNOT RESOLVE DNS REQUESTS WHEN BEHIND MULLVAD VPN
      unbound = {
        enable = true;
        checkconf = false;
        enableRootTrustAnchor = true;
        resolveLocalQueries = true;
        stateDir = "/var/lib/unbound";
        settings = {
          forward-zone = [
            {
              ## requests to tailnet hosts should be forwarded to Tailscale MagicDNS
              name = lib.constants.tailscale-domain;
              forward-addr = [
                "100.100.100.100"
              ];
            }
            {
              name = "adblock.dns.mullvad.net";
              forward-tls-upstream = true;
              forward-addr = [
                "194.242.2.3@853#adblock.dns.mullvad.net"
                "2a07:e340::3@853#adblock.dns.mullvad.net"
                "1.1.1.1@853#one.one.one.one"
                "2606:4700:4700::1111@853#one.one.one.one"
              ];
            }
            {
              name = ".";
              forward-tls-upstream = true;
              forward-first = false;
              forward-host = [
                "adblock.dns.mullvad.net#adblock.dns.mullvad.net"
              ];
            }
          ];

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

            tls-cert-bundle = "/etc/ssl/certs/ca-bundle.crt";

            ## configuration from https://joshua.hu/encrypted-dns-over-tls-unbound-mullvad-freebsd-block-unencrypted-dns-traffic
            hide-identity = true;
            hide-trustanchor = true;
            harden-large-queries = true;
            harden-referral-path = true;
            harden-algo-downgrade = true;
            qname-minimisation-strict = true;
            use-caps-for-id = true;

            # Performance settings
            prefetch = true;
            prefetch-key = true;
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
