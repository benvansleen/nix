lib: overlays:
{ nixpkgs, systems, ... }@inputs:

let
  nixFilesInDir =
    dir:
    lib.mapAttrsToList (name: _: dir + ("/" + name)) (
      lib.filterAttrs (
        name: type:
        !lib.hasPrefix "." name
        && (
          type == "directory" || (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix")
        )
      ) (builtins.readDir dir)
    );

  mkPkgs = cfg: import nixpkgs cfg;
in
{
  importAll = dir: { imports = nixFilesInDir dir; };

  mkSystem =
    system: extraModules:
    (
      let
        pkgs-config = { inherit system overlays; };
        pkgs = mkPkgs pkgs-config;
        pkgs-unfree = mkPkgs (
          pkgs-config
          // {
            config.allowUnfree = true;
          }
        );
      in
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgs pkgs-unfree;
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
