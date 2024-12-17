{
  config,
  lib,
  impermanence,
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

  imports = [
    impermanence.nixosModules.impermanence
  ];

  config = mkIf cfg.enable {
    # Ensure all necessary state is preserved according to nixos manual:
    # https://nixos.org/manual/nixos/stable/#ch-system-state
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
      ];
      files = [
        "/etc/machine-id"
        # "/etc/passwd"
        # "/etc/group"
        # "/etc/shadow"
        # "/etc/gshadow"
        # "/etc/subuid"
        # "/etc/subgid"

        # Investigate declarative ssh key config
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };

    # When /etc is not persisted, sudo lectures on first use every boot
    security.sudo.extraConfig = ''
      Defaults lecture=never
    '';

    users.mutableUsers = false;
  };
}
