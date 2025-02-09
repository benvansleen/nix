{
  config,
  pkgs,
  pkgs-stable,
  pkgs-unfree,
  lib,
  home-manager,
  nix-index-database,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home-manager;
in
{
  options.modules.home-manager = {
    enable = mkEnableOption "home-manager";
  };

  imports = [
    home-manager.nixosModules.home-manager
  ];

  config = mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        pkgs = if config.machine.allowUnfree then pkgs-unfree else pkgs;
        systemConfig = config;
        inherit pkgs-stable nix-index-database;
      };
    };
  };
}
