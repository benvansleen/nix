{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.display-manager;
in
{
  options.modules.display-manager = {
    enable = mkEnableOption "display-manager";
  };

  config = mkIf cfg.enable {
    services = {
      displayManager.sddm = {
        enable = true;
        extraPackages = with pkgs; [ qt6.qtmultimedia ];
        wayland.enable = true;
        theme = "${import ./sddm-theme.nix {
          inherit pkgs;
          image = ./sddm-background.png;
        }}";
      };
    };
  };
}
