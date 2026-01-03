{
  disko,
  ...
}:

{
  imports = [
    disko.nixosModules.disko
  ];

  config = {
    boot = {
      initrd.systemd = {
        enable = true;
        tpm2.enable = true;
      };
      loader.efi.efiSysMountPoint = "/boot";
    };
    security.tpm2.enable = true;
    services.fstrim.enable = true;
    disko.devices = {
      disk.main = {
        type = "disk";
        device = "/dev/nvme0n1";
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
                mountpoint = "/nix";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "logbsize=256k"
                ];
                extraArgs = [
                  "-m"
                  "reflink=1"
                ];
              };
            };
            luks = {
              ## Upon first boot, imperatively store decryption key in motherboard TPM2 module
              ## After running, partition is automatically decrypted on boot
              ## `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p3`
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                  crypttabExtraOpts = [
                    "tpm2-device=auto"
                    "tpm2-measure-pcr=yes"
                  ];
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
        ];
      };
    };
  };
}
