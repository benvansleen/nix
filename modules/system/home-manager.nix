{
  config,
  lib,
  home-manager,
  globals,
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
      extraSpecialArgs = { inherit globals; };
    };
  };
}
