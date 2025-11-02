{
  self,
  config,
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
        inherit self nix-index-database;
      };
    };
  };
}
