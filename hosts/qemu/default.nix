{ nixpkgs, home-manager, ...}:

let
  system = "x86_64-linux";
  pkgs = nixpkgs.legacyPackages.${system};
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit pkgs home-manager; };
  modules = [
    ../../common/base-system.nix
    ./system.nix
  ];
}
