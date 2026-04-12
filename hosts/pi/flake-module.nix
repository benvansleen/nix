{ inputs, ... }:
{
  flake.modules.nixos.pi = {
    imports = [
      ../default.nix
      ../../modules/system
      inputs.self.modules.nixos.homeManager
      inputs.self.modules.nixos.tailscale
      inputs.self.modules.nixos.ben
      ./default.nix
    ];
  };
}
