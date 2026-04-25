{ inputs, ... }:

{
  flake.modules.nixos.desktop = {
    imports = with inputs.self.modules.nixos; [
      base-host
      desktop-configuration
      desktop-disk
      desktop-hardware

      btrfs
      inputs.self.modules.nixos."borgbackup/client"
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
