{ inputs, ... }:
{
  flake.modules.nixos.desktop = {
    imports = [
      ../default.nix
      ../../modules/system
      inputs.self.modules.nixos.homeManager
      inputs.self.modules.nixos.firefox
      inputs.self.modules.nixos.ben
      ./default.nix
    ];
  };
}
