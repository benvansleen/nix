{ inputs, ... }:
{
  flake.modules.nixos.desktop = {
    imports = with inputs.self.modules.nixos; [
      ../default.nix
      ./default.nix

      ben

      btrfs
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
      searx
      secureboot
      sops
      stylix
      tailscale
      zsa
    ];
  };
}
