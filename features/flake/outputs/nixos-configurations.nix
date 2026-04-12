{ inputs, ... }:
let
  localLib = import ../../../lib inputs;
  overlays = import ../../../overlays (inputs // { lib = localLib; });
  mkFlakeHostSystem =
    hostModule:
    localLib.nixosSystem {
      specialArgs = inputs;
      modules = [
        {
          nixpkgs = {
            inherit overlays;
          };
        }
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
