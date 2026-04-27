{ self, ... }:
{
  flake.modules.nixos.laptop = {
    imports = with self.modules.nixos; [
      base-host
      laptop-configuration
      laptop-disk
      laptop-hardware

      self.modules.nixos."borgbackup/client"
      btrfs
      clonix
      containers
      displayManager
      firefox
      secureboot
      stylix
      zsa
    ];

    config.machine = {
      name = "laptop";
      desktop = true;
      powerful = false;
      allowUnfree = false;
    };
  };
}
