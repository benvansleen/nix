{
  globals,
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home.window-manager;
in
globals.importAll lib ./.
// {
  options.modules.home.window-manager = {
    enable = mkEnableOption "window-manager";
  };

  config = mkIf cfg.enable {
    modules.home.window-manager = {
      hyprland.enable = true;
    };

    # hypridle
    # hyprlock

    wayland.windowManager.hyprland.settings = {
      exec-once = [
        "systemctl --user start --now hyprpaper.service"
      ];
    };
    services.hyprpaper = {
      enable = true;
      settings =
        let
          wallpaper = ./pensacola-beach-dimmed.png;
          wallpaper' = builtins.toString wallpaper;
        in
        {
          ipc = "off";
          splash = false;

          preload = [
            wallpaper'
          ];
          wallpaper = [
            ", ${wallpaper'}"
          ];

          # wallpaper = {
          #   "DP-1,"
          # };
        };
    };

  };
}
