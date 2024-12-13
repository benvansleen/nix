{ nixpkgs, systems, ... }@inputs:

{
  mkSystem =
    {
      globals,
      overlays,
      nixpkgs,
    }:
    system: extraModules:
    (
      let
        pkgs = import nixpkgs { inherit system overlays; };
      in
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgs globals;
        } // inputs;
        modules = [
          ./common/base-system.nix
        ] ++ extraModules;
      }
    );

  eachSystem =
    f:
    nixpkgs.lib.genAttrs (import systems) (
      system:
      f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
      }
    );
}
