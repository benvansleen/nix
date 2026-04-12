{
  flake.modules.nixos.grafana =
    { config, lib, ... }:
    {
      options.modules.grafana = with lib; {
        enable = mkEnableOption "grafana";
        port = mkOption {
          type = types.port;
          default = 2342;
          description = "access grafana on this port";
        };
      };

      config = {
        services.grafana = {
          enable = true;
          settings = {
            "auth.proxy" = {
              enabled = true;
              auto_sign_up = true;
              enable_login_token = false;
            };
            server = {
              http_addr = "0.0.0.0";
              http_port = config.modules.grafana.port;
            };
            # TODO: Preserve pre-26.05 behavior until this moves to explicit secret management.
            security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
          };
        };
        persist.directories = with config.services.grafana; [
          dataDir
        ];
      };
    };
}
