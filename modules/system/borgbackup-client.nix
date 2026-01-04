{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    ;
  backupConfig = import ../../shared/backups.nix;
in
{
  config = mkIf (backupConfig.clients ? ${config.machine.name}) {
    services.borgbackup.jobs = {
      "${config.machine.name}-backups" = {
        inherit (backupConfig.clients.${config.machine.name}) paths;
        repo = "root@${lib.constants.backup-machine}:${lib.constants.backup-path}/borgbackup/${config.machine.name}";

        ## using tailscale ssh
        environment.BORG_RSH = "ssh -o StrictHostKeyChecking=accept-new";

        compression = "auto,zstd";
        encryption.mode = "none"; # TODO: add encryption w/ key managed by sops

        startAt = "hourly";
        persistentTimer = true;
        prune.keep = {
          within = "1d";
          daily = 7;
          weekly = 4;
        };

        extraCreateArgs = "--verbose --progress --stats";
      };
    };
    system.activationScripts."create-root-borg-dirs".text = ''
      mkdir -p /root/.config/borg
      chmod 700 /root/.config/borg

      mkdir -p /root/.cache/borg
      chmod 700 /root/.cache/borg
    '';
  };
}
