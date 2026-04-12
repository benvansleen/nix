{ inputs, ... }:
{
  flake.modules.nixos.pi = {
    imports = [
      ../default.nix
      inputs.self.modules.nixos.clonix
      inputs.self.modules.nixos.containers
      inputs.self.modules.nixos.grafana
      inputs.self.modules.nixos.nixosCli
      inputs.self.modules.nixos."prometheus/client"
      inputs.self.modules.nixos."prometheus/server"
      inputs.self.modules.nixos.sops
      inputs.self.modules.nixos.searx
      inputs.self.modules.nixos.homeManager
      inputs.self.modules.nixos.tailscale
      inputs.self.modules.nixos.unbound
      inputs.self.modules.nixos.ben
      ./default.nix
    ];
  };
}
