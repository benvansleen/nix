{ inputs, lib, ... }:

let
  # localLib = import ../../../lib inputs;
  mkFlakeHostSystem =
    hostModule:
    lib.nixosSystem {
      specialArgs = inputs;
      modules = [
        inputs.self.overlaid
        hostModule
      ];
    };
in
{
  flake.nixosConfigurations = {
    desktop = mkFlakeHostSystem inputs.self.modules.nixos.desktop;
    laptop = mkFlakeHostSystem inputs.self.modules.nixos.laptop;
    pi = mkFlakeHostSystem inputs.self.modules.nixos.pi;
  };
}
