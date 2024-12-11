{ pkgs, ... }:

{
  wayland.windowManager.hyprland = import ./hyprland.nix { inherit pkgs; };

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

}
