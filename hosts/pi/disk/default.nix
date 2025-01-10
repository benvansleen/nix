{ lib, ... }:

{
  config = {
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = [ "noatime" ];
      };

      "${lib.constants.backup-path}" = {
        device = "/dev/disk/by-id/usb-WD_easystore_25FC_575837314132395030304458-0:0-part1";
        fsType = "ext4";
        options = [
          "users"
          "nofail"
        ];
      };
    };
  };
}
