{ inputs, ... }:
{
  flake.modules.nixos.desktop = {
    imports = with inputs.self.modules.nixos; [
      ../default.nix
      ./default.nix

      ben

      btrfs
      inputs.self.modules.nixos."borgbackup/client"
      clonix
      containers
      crossplatformBuilder
      displayManager
      firefox
      homeManager
      impermanence
      nixosCli
      inputs.self.modules.nixos."prometheus/client"
      remotebuilder
      secureboot
      sops
      stylix
      tailscale
      zsa
    ];
  };
}
