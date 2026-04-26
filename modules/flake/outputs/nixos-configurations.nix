{ self, lib, ... }:

let
  mkSystem =
    host:
    lib.nixosSystem {
      modules = [
        self.overlaid
        host
      ];
    };
in
{
  flake.nixosConfigurations = {
    desktop = mkSystem self.modules.nixos.desktop;
    laptop = mkSystem self.modules.nixos.laptop;
    pi = mkSystem self.modules.nixos.pi;
  };
}
