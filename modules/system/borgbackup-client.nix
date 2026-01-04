{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    ;

  isLocalBackup = config.machine.name == lib.constants.backup-machine;
  host = if !isLocalBackup then "root@${lib.constants.backup-machine}:" else "";
  backupConfig = import ../../shared/backups.nix;
in
{
  config = mkIf (backupConfig.clients ? ${config.machine.name}) {
    services.borgbackup.jobs = {
      "${config.machine.name}-backups" = {
        inherit (backupConfig.clients.${config.machine.name}) paths exclude;
        repo = "${host}${lib.constants.backup-path}/borgbackup/${config.machine.name}";

        environment = {
          ## using tailscale ssh
          ${if !isLocalBackup then "BORG_RSH" else null} = "ssh -o StrictHostKeyChecking=accept-new";
          BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "yes";
        };

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
