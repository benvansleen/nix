{
  disko.devices = {

	disk.main = {
	  device = "/dev/sda";
	  type = "disk";
	  content = {
		type = "gpt";
		partitions = {
		  boot = {
			size = "1M";
			type = "EF02"; # for grub MBR
		  };
		  ESP = {
			size = "500M";
			type = "EF00";
			content = {
			  type = "filesystem";
			  format = "vfat";
			  mountpoint = "/boot";
			  mountOptions = [ "umask=0077" ];
			};
		  };
		  nix = {
			end = "-2G";
			content = {
			  type = "filesystem";
			  format = "ext4";
			  mountpoint = "/nix";
			};
		  };
		  swap = {
			size = "100%";
			content = {
			  type = "swap";
			  discardPolicy = "both";
			  resumeDevice = true; # resume from hiberation from this device
			};
		  };
		};
	  };
	};

	nodev."/" = {
	  fsType = "tmpfs";
	  mountOptions = [
		"size=2G"
		"defaults"
		"mode=755"
	  ];
	};

  };
}
