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
      self.modules.nixos."k3s/agent"
      firefox
      remotebuilder
      secureboot
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
