_:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = {
        WLR_NO_HARDWARE_CURSORS = "1";
        WLR_RENDERER_ALLOW_SOFTWARE = "1";
      };
      cursor = {
        noHardwareCursors = true;
      };
    };
  };

  # hypridle
  # hyprlock

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = true;

      # wallpaper = {
      #   "DP-1,"
      # };
    };
  };
}
