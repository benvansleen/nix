{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.window-manager.hyprland;

in
{
  options.modules.window-manager.hyprland = {
    enable = mkEnableOption "hyprland";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = lib.optimizeForThisHostIfPowerful {
        config = osConfig;
        pkg = pkgs.hyprland;
      };
      portalPackage = lib.optimizeForThisHostIfPowerful {
        config = osConfig;
        pkg = pkgs.xdg-desktop-portal-hyprland;
      };
      systemd.enable = false; # Conflicts with UWSM
      plugins = with pkgs.hyprlandPlugins; [
      ];
    };
  };
}
