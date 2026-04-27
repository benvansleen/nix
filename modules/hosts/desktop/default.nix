{ self, ... }:

{
  flake.modules.nixos.desktop = {
    imports = with self.modules.nixos; [
      base-host
      desktop-configuration
      desktop-disk
      desktop-hardware

      btrfs
      self.modules.nixos."borgbackup/client"
      clonix
      containers
      crossplatformBuilder
      displayManager
      firefox
      remotebuilder
      secureboot
      stylix
      zsa
    ];

    config.machine = {
      name = "desktop";
      desktop = true;
      powerful = true;
      allowUnfree = true;
    };
  };
}
