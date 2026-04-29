{
  flake.modules.nixos."prometheus/server" =
    { config, lib, ... }:
    {
      options.modules.prometheus.server = with lib; {
        enable = mkEnableOption "prometheus/server";
        port = mkOption {
          type = types.port;
          default = 9001;
        };
        scrapeConfigs = mkOption {
          type = with types; listOf anything;
          default = [ ];
        };
      };

      config =
        let
          cfg = config.modules.prometheus.server;
        in
        lib.mkIf cfg.enable {
          services.prometheus = {
            enable = true;
            inherit (cfg) port;
            inherit (cfg) scrapeConfigs;
            retentionTime = "1y";
          };
        };
    };
}
