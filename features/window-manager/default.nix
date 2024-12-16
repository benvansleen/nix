{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.features.window-manager;
in
{
  imports = [
    ./hyprland.nix
  ];

  options.features.window-manager = {
    enable = mkEnableOption "window-manager";
  };

  config = mkIf cfg.enable {
    features.hyprland.enable = true;

    # hypridle
    # hyprlock

    services.hyprpaper = {
      enable = true;
      settings =
        let
          wallpaper = "~/Pictures/pensacola-beach-dimmed.png";
        in
        {
          ipc = "on";
          splash = true;

          preload = [
            wallpaper
          ];
          wallpaper = [
            ",${wallpaper}"
          ];

          # wallpaper = {
          #   "DP-1,"
          # };
        };
    };

  };
}
