{
  description = "NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ...}@inputs:
    let
      # inherit (self) outputs;
      # system = "x86_64-linux";
      # pkgs = nixpkgs.legacyPackages.${system};
      host = "nixos";
    in
      rec {
        nixosConfigurations = {
          qemu = import ./hosts/qemu { inherit nixpkgs home-manager; };
          # qemu = nixpkgs.lib.nixosSystem {
          #   system = system;
          #   specialArgs = { inherit pkgs inputs outputs; };
          #   modules = [
          #     ./hosts/qemu
          #   ];
          # };
        };

        # homeConfigurations = {
        #   "ben@qemu" = nixosConfigurations.qemu.config.home-manager.users.ben.home;
        # };
      };
}
