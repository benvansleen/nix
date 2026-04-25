{ inputs, ... }:
{
  flake.modules.nixos.laptop = {
    imports = with inputs.self.modules.nixos; [
      base-host
      laptop-configuration
      laptop-disk
      laptop-hardware

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
