{ inputs, ... }:
{
  flake.modules.nixos.laptop = {
    imports = [
      ../default.nix
      inputs.self.modules.nixos.btrfs
      inputs.self.modules.nixos.clonix
      inputs.self.modules.nixos.containers
      inputs.self.modules.nixos.displayManager
      inputs.self.modules.nixos.nixosCli
      inputs.self.modules.nixos."prometheus/client"
      inputs.self.modules.nixos.secureboot
      inputs.self.modules.nixos.searx
      inputs.self.modules.nixos.sops
      inputs.self.modules.nixos.homeManager
      inputs.self.modules.nixos.firefox
      inputs.self.modules.nixos.stylix
      inputs.self.modules.nixos.tailscale
      inputs.self.modules.nixos.impermanence
      inputs.self.modules.nixos.ben
      inputs.self.modules.nixos.zsa
      ./default.nix
    ];
  };
}
