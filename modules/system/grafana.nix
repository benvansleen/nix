{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.grafana;
in
{
  options.modules.grafana = {
    enable = mkEnableOption "grafana";
    port = mkOption {
      type = types.port;
      default = 2342;
      description = "access grafana on this port";
    };
  };

  config = mkIf cfg.enable {
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
          http_port = cfg.port;
        };
      };
    };

    modules.impermanence.persistedDirectories = with config.services.grafana; [
      dataDir
    ];
  };
}
