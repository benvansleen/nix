{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption mkOption;
  cfg = config.modules.system.impermanence;
in
{
  options.modules.system.impermanence = {
    enable = mkEnableOption "impermanence";
    persistRoot = mkOption {
      type = lib.types.str;
      default = "/";
      example = "/nix/persist";
      description = "where to mount persistent storage";
    };
  };

  config = mkIf cfg.enable {
    environment.persistence.${cfg.persistRoot} = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd"
        "/var/log/journal"
        "/etc/NetworkManager/system-connections"
        "/etc/nixos"
      ];
      files = [
        "/etc/machine-id"

        # Investigate declarative ssh key config
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };
}
