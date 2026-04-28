{
  flake.modules.kubernetes.nginx =
    { config, lib, ... }:
    {
      options.modules.nginx = with lib; {
        enable = mkEnableOption "nginx";
      };

      config =
        let
          cfg = config.modules.nginx;
        in
        lib.mkIf cfg.enable {
          applications.nginx = {
            namespace = "nginx";
            createNamespace = true;
            resources = {
              deployments.nginx.spec = {
                replicas = 2;
                selector.matchLabels.app = "nginx";
                template = {
                  metadata.labels.app = "nginx";
                  spec = {
                    containers.nginx = {
                      image = "nginx:1.25.1";
                      ports.http.containerPort = 80;
                      volumeMounts."/usr/share/nginx/html".name = "html";
                    };
                    volumes.html.configMap.name = "nginx-html";
                  };
                };
              };

              services.nginx.spec = {
                selector.app = "nginx";
                ports.http.port = 80;
              };

              configMaps.nginx-html.data."index.html" = ''
                <!DOCTYPE html>
                <html>
                  <body>
                    <h1>Hello from nixidy!</h1>
                  </body>
                </html>
              '';

              ingresses.nginx.spec = lib.mkIf config.modules.tailscale-operator.enable {
                ingressClassName = "tailscale";
                tls = [
                  {
                    hosts = [ "nginx" ];
                  }
                ];
                defaultBackend.service = {
                  name = "nginx";
                  port.name = "http";
                };
              };
            };
          };
        };
    };
}
