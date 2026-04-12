{ inputs, ... }:
let
  localLib = import ../../../lib inputs;
  mkSystem = localLib.mkSystem (import ../../../overlays (inputs // { lib = localLib; }));
in
{
  flake.nixosConfigurations = {
    desktop = mkSystem ../../../hosts/desktop;
    laptop = mkSystem ../../../hosts/laptop;
    pi = mkSystem ../../../hosts/pi;
  };
}
