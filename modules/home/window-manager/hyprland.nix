{
  config,
  pkgs,
  lib,
  systemConfig,
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
        config = systemConfig;
        pkg = pkgs.hyprland;
      };
      systemd.enable = false; # Conflicts with UWSM
      plugins = with pkgs.hyprlandPlugins; [
      ];
    };
  };
}
