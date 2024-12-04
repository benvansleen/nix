{ nixpkgs, overlays, ... }@inputs:

let
  system = "x86_64-linux";
  pkgs = import nixpkgs { inherit system overlays; };
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit pkgs;
  } // inputs;
  modules = [
    ../../common/base-system.nix
    ./system.nix
  ];
}
