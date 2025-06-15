{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.zsa;
in
{

  options.modules.zsa.enable = mkEnableOption "requirements for managing zsa keyboard firmware";

  config = mkIf cfg.enable {
    hardware.keyboard.zsa.enable = true;
    environment.systemPackages = with pkgs; [ unfree.keymapp ];
  };
}
