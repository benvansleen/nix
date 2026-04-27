{ inputs, ... }:

{
  flake.modules.nixos.homeManager = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };

    # since you installed Home Manager via its NixOS module and
    # 'home-manager.useUserPackages' is enabled, you need to add
    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];
  };
}
