{
  flake.modules.nixos.btrfs =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.modules.btrfs = with lib; {
        mountpoint = mkOption {
          type = types.str;
          example = "/persist";
          description = "where should commands operate?";
        };
      };

      config =
        let
          cfg = config.modules.btrfs;
        in
        {
          services = {
            btrfs.autoScrub = {
              enable = true;
              fileSystems = [ cfg.mountpoint ];
            };
          };

          systemd.services.btrfs-balance = {
            description = "Balance btrfs filesystem";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${lib.getExe pkgs.btrfs-progs} balance start -dusage=50 -musage=50 ${cfg.mountpoint}";
            };
          };
          systemd.timers.btrfs-balance = {
            description = "Balance btrfs filesystem monthly";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "monthly";
              Persistent = true;
            };
          };
        };
    };
}
