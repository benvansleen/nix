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
      enable = osConfig.machine.desktop;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      # package = lib.optimizeForThisHostIfPowerful {
      #   config = osConfig;
      #   pkg = pkgs.stable.hyprland;
      # };
      # portalPackage = lib.optimizeForThisHostIfPowerful {
      #   config = osConfig;
      #   pkg = pkgs.stable.xdg-desktop-portal-hyprland;
      # };
      systemd.enable = false; # Conflicts with UWSM
      plugins = with pkgs.hyprlandPlugins; [
      ];
    };
  };
}
