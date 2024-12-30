{
  config,
  pkgs,
  pkgs-unfree,
  lib,
  home-manager,
  nix-index-database,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system.home-manager;
in
{
  options.modules.system.home-manager = {
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
        inherit nix-index-database;
      };
    };
  };
}
