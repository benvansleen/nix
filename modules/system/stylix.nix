{
  config,
  lib,
  stylix,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system.stylix;
in
{
  options.modules.system.stylix = {
    enable = mkEnableOption "stylix";
  };

  imports = [
    stylix.nixosModules.stylix
  ];

  config = mkIf cfg.enable {
    stylix.enable = true;
  };
}
