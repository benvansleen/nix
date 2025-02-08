{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.maybe;
in
{
  options.modules.maybe = {
    enable = mkEnableOption "maybe-financials";
    port = mkOption {
      type = types.port;
      default = 3000;
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers =
      let
        POSTGRES_USER = "maybe_user";
        POSTGRES_DB = "maybe_production";
        network = "host";
      in
      {
        maybe-financial = {
          image = "ghcr.io/maybe-finance/maybe:latest";
          environment = {
            SELF_HOSTED = "true";
            RAILS_FORCE_SSL = "false";
            RAILS_ASSUME_SSL = "false";
            DB_HOST = "localhost";
            SYNTH_API_KEY = "";
            inherit POSTGRES_DB POSTGRES_USER;
          };
          environmentFiles = [
            config.sops.templates."maybe.env".path
          ];
          volumes = [
            "app-storage:/rails/storage"
          ];
          ports = [
            "127.0.0.1:${toString cfg.port}:3000"
          ];
          dependsOn = [ "maybe-postgres" ];
          extraOptions = [
            "--network=${network}"
          ];
        };

        maybe-postgres = {
          image = "postgres:16";
          environment = {
            inherit POSTGRES_DB POSTGRES_USER;
          };
          environmentFiles = [
            config.sops.templates."maybe.env".path
          ];
          volumes = [
            "postgres-data:/var/lib/postgresql/data"
          ];
          extraOptions = [
            "--network=${network}"
          ];
        };
      };

    sops.templates."maybe.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder.maybe_postgres_password}
      SECRET_KEY_BASE=${config.sops.placeholder.maybe_secret_key_base}
    '';
  };
}
