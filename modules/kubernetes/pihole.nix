{ self, ... }:

let
  namespace = "pihole";
  secret-name = "pihole-webpassword";
in
{
  flake.modules.nixos.k3s-pihole =
    {
      config,
      lib,
      ...
    }:
    {
      options.modules.k3s-pihole = with lib; {
        enable = mkEnableOption "k3s pihole prerequisites and secrets";
      };

      config =
        let
          cfg = config.modules.k3s-pihole;
        in
        lib.mkIf cfg.enable {
          # Pi-hole runs in a hostNetwork pod on the k3s server so LAN clients can
          # keep using the Pi's port 53 directly.
          modules.tailscale.tailscale-up-extra-args = [
            "--accept-dns=true"
          ];
          services.resolved.enable = false;

          networking.firewall = {
            allowedTCPPorts = lib.mkForce [ 53 ];
            allowedUDPPorts = lib.mkForce [ 53 ];
          };

          system.activationScripts.mk-pihole-persist-dirs.text = /* sh */ ''
            mkdir -p /etc/pihole
            mkdir -p /etc/dnsmasq.d
          '';
          modules.k3s.secrets = [
            {
              inherit namespace;
              name = secret-name;
              dataFromSops = {
                FTLCONF_webserver_api_password = config.sops.secrets.pihole_webpassword.path;
                PIHOLE_PASSWORD = config.sops.secrets.pihole_webpassword.path;
              };
            }
          ];
        };
    };

  flake.modules.kubernetes.pihole =
    { config, lib, ... }:
    {
      options.modules.pihole = with lib; {
        enable = mkEnableOption "pihole";
      };

      config =
        let
          cfg = config.modules.pihole;
        in
        lib.mkIf cfg.enable {
          nixidy.applicationImports = lib.mkIf config.modules.gateway.enable [ ../../generated/traefik.nix ];

          applications.pihole = {
            inherit namespace;
            createNamespace = true;

            resources = {
              configMaps.unbound-conf.data."unbound.conf" = ''
                server:
                  username: "" # for nix-built image
                  port: 15335
                  interface: 127.0.0.1
                  access-control: 127.0.0.0/8 allow
                  verbosity: 1

                  # Tailscale LoadBalancer IP for Service/gateway/traefik.
                  # Check with: kubectl -n gateway get svc traefik -o wide
                  local-zone: "k3s.vansleen.dev." redirect
                  local-data: "k3s.vansleen.dev. 300 IN A 100.104.245.35"

                  qname-minimisation: yes
                  edns-buffer-size: 1232
                  prefetch: yes
                  prefetch-key: yes
                  hide-identity: yes
                  hide-version: yes
                  harden-large-queries: yes
                  harden-referral-path: yes
                  harden-algo-downgrade: yes
                  tls-cert-bundle: /etc/ssl/certs/ca-certificates.crt

                forward-zone:
                  name: "${self.constants.tailscale-domain}"
                  forward-addr: 100.100.100.100

                forward-zone:
                  name: "."
                  forward-tls-upstream: yes
                  forward-addr: 194.242.2.3@853#adblock.dns.mullvad.net
                  forward-addr: 1.1.1.1@853#one.one.one.one
              '';

              httpRoutes.pihole.spec = lib.mkIf config.modules.gateway.enable {
                parentRefs = [
                  {
                    name = "public";
                    namespace = "gateway";
                    sectionName = "websecure";
                  }
                ];
                hostnames = [ "pihole.k3s.vansleen.dev" ];
                rules = [
                  {
                    name = "root-redirect";
                    matches = [
                      {
                        path = {
                          type = "Exact";
                          value = "/";
                        };
                      }
                    ];
                    filters = [
                      {
                        type = "RequestRedirect";
                        requestRedirect = {
                          path = {
                            type = "ReplaceFullPath";
                            replaceFullPath = "/admin/";
                          };
                          statusCode = 302;
                        };
                      }
                    ];
                  }
                  {
                    name = "backend";
                    backendRefs = [
                      {
                        name = "pihole-web";
                        port = 80;
                      }
                    ];
                  }
                ];
              };

              deployments.pihole.spec = {
                replicas = 1;
                strategy.type = "Recreate";
                selector.matchLabels.app = "pihole";
                template = {
                  metadata.labels.app = "pihole";
                  spec = {
                    hostNetwork = true;
                    dnsPolicy = "Default";
                    nodeSelector."kubernetes.io/hostname" = "pi";
                    containers.pihole = {
                      ## MUST pre-pull image before upgrading; otherwise will imagepull will fail
                      ## due to dns outage. `ssh pi 'sudo k3s ctr images pull docker.io/pihole/pihole:<tag>'`
                      image = "pihole/pihole:2026.04.1";
                      env = {
                        TZ.value = "America/New_York";
                        PIHOLE_INTERFACE.value = "end0";
                        FTLCONF_dns_upstreams.value = "127.0.0.1#15335";
                        FTLCONF_webserver_port.value = "18080";
                        FTLCONF_dns_dnssec.value = "false";
                        FTLCONF_dns_listeningMode.value = "all";
                        FTLCONF_webserver_session_timeout.value = "604800";
                      };
                      envFrom = [
                        { secretRef.name = secret-name; }
                      ];
                      ports = {
                        dns-tcp = {
                          containerPort = 53;
                          protocol = "TCP";
                        };
                        dns-udp = {
                          containerPort = 53;
                          protocol = "UDP";
                        };
                        http.containerPort = 18080;
                      };
                      volumeMounts = {
                        "/etc/pihole".name = "pihole-etc";
                        "/etc/dnsmasq.d".name = "dnsmasq";
                      };
                    };
                    containers.unbound = {
                      ## if image not found, use `nix run .#update-unbound`
                      image = "docker.io/library/unbound:latest";

                      ports.unbound.containerPort = 15335;
                      volumeMounts."/etc/unbound/unbound.conf" = {
                        name = "unbound-conf";
                        subPath = "unbound.conf";
                      };
                    };
                    volumes = {
                      pihole-etc.hostPath = {
                        path = "/etc/pihole";
                        type = "DirectoryOrCreate";
                      };
                      dnsmasq.hostPath = {
                        path = "/etc/dnsmasq.d";
                        type = "DirectoryOrCreate";
                      };
                      unbound-conf.configMap.name = "unbound-conf";
                    };
                  };
                };
              };

              services.pihole-web.spec = {
                selector.app = "pihole";
                ports.http = {
                  port = 80;
                  targetPort = "http";
                };
              };
            };
          };
        };
    };
}
