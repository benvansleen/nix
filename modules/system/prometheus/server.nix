{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.prometheus.server;
in
{
  options.modules.prometheus.server = {
    enable = mkEnableOption "prometheus-server";
    port = mkOption {
      type = types.port;
      default = 9001;
    };
    scrapeConfigs = mkOption {
      type = with types; listOf anything;
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      inherit (cfg) port;
      inherit (cfg) scrapeConfigs;
    };
  };
}
