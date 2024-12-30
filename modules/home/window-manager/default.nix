{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.home.window-manager;
  mkUwsmService = service: "systemctl --user start --now ${service}.service";
in
lib.importAll ./.
// {
  options.modules.home.window-manager = {
    enable = mkEnableOption "window-manager";
    terminal = mkOption {
      type = types.package;
      description = "terminal emulator to use";
      default = pkgs.alacritty;
    };
  };

  config = mkIf cfg.enable {
    modules.home.window-manager = {
      hyprland.enable = true;
      gnome-xterm-compat = {
        enable = true;
        inherit (cfg) terminal;
      };
    };

    # hypridle
    # hyprlock

    wayland.windowManager.hyprland.settings = {
      exec-once = lib.map mkUwsmService [
        "hyprpaper" # Enabled by UWSM + stylix
        "gammastep"
      ];
    };
    services = {
      gammastep = {
        enable = true;
        provider = "manual";
        latitude = 38.8816;
        longitude = -77.0910;
        settings = {
          general = {
            temp-day = lib.mkForce 6000;
            temp-night = lib.mkForce 3000;
            fade = 1;
            gamma = 0.8;
            adjustment-method = "wayland";
          };
        };
      };
    };
  };
}
