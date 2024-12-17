{ nixpkgs, systems, ... }@inputs:

let
  nixFilesInDir =
    lib: dir:
    lib.mapAttrsToList (name: _: dir + ("/" + name)) (
      lib.filterAttrs (
        name: type:
        !lib.hasPrefix "." name
        && (
          type == "directory" || (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix")
        )
      ) (builtins.readDir dir)
    );
  importAll = lib: dir: { imports = nixFilesInDir lib dir; };
in
{
  inherit importAll;

  mkSystem =
    {
      nixpkgs,
      overlays,
      globals,
    }:
    system: extraModules:
    (
      let
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = globals.allowUnfree;
        };
      in
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgs globals;
        } // inputs;
        modules = [
          ./modules/system
          ./hosts
          ./users

          {
            environment.etc.nixos.source = ./.;
          }
        ] ++ extraModules;
      }
    );

  mkUser =
    {
      enable,
      user,
      extraHomeModules,
      extraConfig,
    }:
    (
      extraConfig
      // {
        home-manager = enable {
          users.${user} = {
            imports = [
              inputs.impermanence.homeManagerModules.impermanence
              inputs.sops-nix.homeManagerModules.sops
              ./modules/home
            ] ++ extraHomeModules;
          };
        };
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
