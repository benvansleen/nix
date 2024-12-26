{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home.cli.alacritty;
in
{
  options.modules.home.cli.alacritty = {
    enable = mkEnableOption "terminal";
  };

  config = mkIf cfg.enable {
    # Create `xterm` binary for `wofi` to launch cli apps
    home.packages = [
      (pkgs.writeShellScriptBin "xterm" ''
        ${pkgs.alacritty}/bin/alacritty "$@"
      '')
    ];
    programs.alacritty = {
      enable = true;
      settings = {
        env.TERM = "alacritty";
        cursor = {
          blink_interval = 750;
          unfocused_hollow = true;
          vi_mode_style = "Block";
          style = {
            blinking = "On";
            shape = "Underline";
          };
        };

        keyboard.bindings = [
          {
            action = "ToggleViMode";
            key = "Space";
            mods = "Control";
            mode = "~Search";
          }
          {
            action = "ScrollHalfPageUp";
            key = "K";
            mods = "Control";
            mode = "Vi|~Search";
          }
          {
            action = "ScrollHalfPageDown";
            key = "J";
            mods = "Control";
            mode = "Vi|~Search";
          }
          {
            action = "Copy";
            key = "Y";
            mode = "Vi|~Search";
          }
          {
            action = "IncreaseFontSize";
            key = "Plus";
            mods = "Control";
          }
          {
            action = "DecreaseFontSize";
            key = "Minus";
            mods = "Control";
          }
        ];

        window = {
          dynamic_padding = true;
          padding = {
            x = 20;
            y = 10;
          };
        };
      };
    };
  };
}
