{ inputs, lib, ... }:

let
  mkSystem =
    host:
    lib.nixosSystem {
      modules = [
        inputs.self.overlaid
        host
      ];
    };
in
{
  flake.nixosConfigurations = {
    desktop = mkSystem inputs.self.modules.nixos.desktop;
    laptop = mkSystem inputs.self.modules.nixos.laptop;
    pi = mkSystem inputs.self.modules.nixos.pi;
  };
}
