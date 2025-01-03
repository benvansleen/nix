{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home.window-manager.hyprland;

in
{
  options.modules.home.window-manager.hyprland = {
    enable = mkEnableOption "hyprland";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = false; # Conflicts with UWSM
      plugins = with pkgs.hyprlandPlugins; [
        hyprexpo
      ];
    };
  };
}
