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
      globals,
      overlays,
      nixpkgs,
    }:
    system: extraModules:
    (
      let
        pkgs = import nixpkgs { inherit system overlays; };
      in
      nixpkgs.lib.nixosSystem rec {
        inherit system;
        specialArgs = {
          inherit pkgs globals;
        } // inputs;
        modules = [
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
            };
          }

          inputs.sops-nix.nixosModules.sops
          {
            sops = {
              defaultSopsFile = ./secrets/default.yaml;
              defaultSopsFormat = "yaml";
              gnupg.sshKeyPaths = [ ];
              age.sshKeyPaths = [
                # The persisted /etc isn't mounted fast enough
                # From https://github.com/profiluefter/nixos-config/blob/09a56c8096c7cbc00b0fbd7f7c75d6451af8f267/sops.nix
                "${globals.persistRoot}/etc/ssh/ssh_host_ed25519_key"
              ];
              secrets.root-password = {
                sopsFile = ./secrets/root-password.sops;
                format = "binary";
                neededForUsers = true;
              };
            };
          }

          ./modules/system
          ./hosts
          ./users
        ] ++ extraModules;
      }
    );

  mkUser =
    user: extraModules: config:
    (
      {
        home-manager.users.${user} = {
          imports = [
            inputs.impermanence.homeManagerModules.impermanence
            inputs.sops-nix.homeManagerModules.sops
            ./modules/home
          ] ++ extraModules;
        };
      }
      // config
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
