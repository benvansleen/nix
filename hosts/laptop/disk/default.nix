{ disko, pkgs, ... }:

{
  imports = [
    disko.nixosModules.disko
  ];

  config = {
    boot.initrd.systemd = {
      enable = true;
      enableTpm2 = true;
    };
    security.tpm2.enable = true;
    environment.systemPackages = with pkgs; [ tpm2-tss tpm2-tools ];

  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1024M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "defaults"
                "umask=0077"
              ];
            };
          };
          nix = {
            size = "250G";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/nix/store";
              mountOptions = [ "defaults" "noatime" "logbsize=256k" ];
              extraArgs = [ "-m reflink=1" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings = {
                allowDiscards = true;
                crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-measure-pcr=yes" ];
              };
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "/swap" = {
                    mountpoint = "/.swap";
                    swap.swapfile.size = "24G";
                  };
                };
              };
            };
          };
        };
      };
    };

    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=16G"
        "defaults"
        "mode=755"
        "compress=zstd"
      ];
    };
  };
  };
}
