{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    ;
  backupConfig = import ../../shared/backups.nix;
in
{
  config = mkIf (config.machine.name == lib.constants.backup-machine) {
    services.borgbackup.repos = lib.mapAttrs (name: _cfg: {
      path = "/mnt/storage/borgbackup/${name}";
      ## Provide a placeholder to satisfy NixOS assertion.
      ## Tailscale SSH will still be the actual authentication layer.
      authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI-PLACEHOLDER-KEY-FOR-NIXOS-CHECK" ];
    }) backupConfig.clients;
  };
}
