let
  namespace = "longhorn-system";
in
{
  flake.modules.kubernetes.longhorn =
    {
      config,
      lib,
      charts,
      ...
    }:
    {
      options.modules.longhorn = with lib; {
        enable = mkEnableOption "Longhorn distributed block storage";
      };

      config = lib.mkIf config.modules.longhorn.enable {
        nixidy.applicationImports = lib.mkIf config.modules.gateway.enable [ ../../generated/traefik.nix ];

        applications.longhorn = {
          inherit namespace;
          createNamespace = true;

          helm.releases.longhorn = {
            chart = charts.longhorn.longhorn;
            values = {
              defaultSettings = {
                defaultDataPath = "/var/lib/longhorn";
                replicaAutoBalance = "disabled";
                replicaSoftAntiAffinity = false;
                storageMinimalAvailablePercentage = 10;
              };

              persistence = {
                defaultClass = true;
                defaultClassReplicaCount = 2;
                reclaimPolicy = "Retain";
              };
            };
          };

          resources.httpRoutes.longhorn.spec = lib.mkIf config.modules.gateway.enable {
            parentRefs = [
              {
                name = "public";
                namespace = "gateway";
                sectionName = "websecure";
              }
            ];
            hostnames = [ "longhorn.vansleen.dev" ];
            rules = [
              {
                backendRefs = [
                  {
                    name = "longhorn-frontend";
                    port = 80;
                  }
                ];
              }
            ];
          };
        };
      };
    };

  flake.modules.nixos.k3s-longhorn =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf config.services.k3s.enable {
        services.openiscsi = {
          enable = true;
          name = config.networking.hostName;
        };

        system.activationScripts.longhorn-iscsiadm = ''
          install -d -m 0755 /usr/bin
          ln -sfn ${pkgs.openiscsi}/bin/iscsiadm /usr/bin/iscsiadm
        '';

        systemd.services.longhorn-data-exec-mount = lib.mkIf config.persist.enable {
          description = "Allow Longhorn to execute engine binaries from its data directory";
          wantedBy = [ "local-fs.target" ];
          after = [ "var-lib-longhorn.mount" ];
          before = [ "local-fs.target" ];
          unitConfig.DefaultDependencies = false;
          path = [ pkgs.util-linux ];
          script = ''
            mountpoint -q /var/lib/longhorn
            mount -o remount,bind,exec /var/lib/longhorn
          '';
        };

        persist.directories = [
          "/var/lib/longhorn"
        ];
      };
    };
}
