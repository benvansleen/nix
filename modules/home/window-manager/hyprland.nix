{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
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

      ## Multiple spaces in `settings` strings results in hard-to-debug
      ## issue w/ empty `home-manager-generation/activate` script
    };
  };
}
