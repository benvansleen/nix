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

        SELF_HOSTED = "true";
        RAILS_FORCE_SSL = "false";
        RAILS_ASSUME_SSL = "false";
        DB_HOST = "localhost";
      in
      {
        maybe-web = {
          image = "ghcr.io/maybe-finance/maybe:latest";
          environment = {
            inherit
              POSTGRES_USER
              POSTGRES_DB
              SELF_HOSTED
              RAILS_FORCE_SSL
              RAILS_ASSUME_SSL
              DB_HOST
              ;
          };
          environmentFiles = [
            config.sops.templates."maybe-rails.env".path
          ];
          volumes = [
            "app-storage:/rails/storage"
          ];
          ports = [
            "127.0.0.1:${toString cfg.port}:3000"
          ];
          dependsOn = [
            "maybe-postgres"
            "maybe-redis"
          ];
          extraOptions = [
            "--network=${network}"
          ];
        };

        maybe-worker = {
          image = "ghcr.io/maybe-finance/maybe:latest";
          entrypoint = "/usr/local/bin/bundle";
          cmd = [
            "exec"
            "sidekiq"
          ];
          environment = {
            inherit
              POSTGRES_USER
              POSTGRES_DB
              SELF_HOSTED
              RAILS_FORCE_SSL
              RAILS_ASSUME_SSL
              DB_HOST
              ;
          };
          environmentFiles = [
            config.sops.templates."maybe-rails.env".path
          ];
          dependsOn = [ "maybe-redis" ];
          extraOptions = [
            ## `maybe` has been archived; do not expect updates to this image
            # "--pull=newer"
            "--network=${network}"
          ];
        };

        maybe-postgres = {
          image = "postgres:16";
          environment = {
            inherit POSTGRES_DB POSTGRES_USER;
          };
          environmentFiles = [
            config.sops.templates."maybe-db.env".path
          ];
          volumes = [
            "postgres-data:/var/lib/postgresql/data"
          ];
          extraOptions = [
            "--network=${network}"
          ];
        };

        maybe-redis = {
          image = "redis:latest";
          environment = {
            inherit POSTGRES_DB POSTGRES_USER;
          };
          volumes = [
            "redis-data:/data"
          ];
          extraOptions = [
            "--network=${network}"
          ];
        };
      };

    sops.templates."maybe-db.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder.maybe_postgres_password}
    '';

    sops.templates."maybe-rails.env".content = ''
      SECRET_KEY_BASE=${config.sops.placeholder.maybe_secret_key_base}
    '';
  };
}
