{ pkgs, ... }:

{
  enable = true;
  settings = {
    "$mainMod" = "SUPER";
    bind = [
      # "$mainMod, Return, exec, ~/.config/guix/etc/sway/alacritty"
      "$mainMod, Return, exec, ${pkgs.alacritty}/bin/alacritty"
      # "$mainMod SHIFT, Return, exec, ~/.config/hypr/special-term"
      "$mainMod, E, exec, emacsclient -c -n"
      "$mainMod, Q, killactive, "
      "$mainMod SHIFT, Q, exit, "
      "$mainMod, F, fullscreen"
      # "$mainMod SHIFT, F, fakefullscreen"
      ", XF86Reload, exec, wlogout"
      ", XF86RFKill, exec, wlogout"
      "$mainMod SHIFT, E, exec, thunar"
      "$mainMod SHIFT, SPACE, togglefloating, "
      # bind = $mainMod, D, exec, wofi --show drun
      "$mainMod, D, exec, nwggrid -server -o 0.7 -n 3"
      "$mainMod, P, pseudo, # dwindle"
      "$mainMod, I, togglesplit, # dwindle"
      ''$mainMod SHIFT, S, exec, grim -g "''$(slurp)" - | swappy -f -''
      # "$mainMod, B, exec, ~/.local/bin/eww open-many bar-0 bar-1 bar-2 --toggle"

      "$mainMod, left,  movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up,    movefocus, u"
      "$mainMod, down,  movefocus, d"
      "$mainMod, h,  movefocus, l"
      "$mainMod, l, movefocus, r"
      "$mainMod, k,    movefocus, u"
      "$mainMod, j,  movefocus, d"
      # "$mainMod, h, exec, ~/.config/hypr/direction l"
      # "$mainMod, l, exec, ~/.config/hypr/direction r"
      # "$mainMod, k, exec, ~/.config/hypr/direction u"
      # "$mainMod, j, exec, ~/.config/hypr/direction d"

      "$mainMod SHIFT, h, movewindow, l"
      "$mainMod SHIFT, l, movewindow, r"
      "$mainMod SHIFT, k, movewindow, u"
      "$mainMod SHIFT, j, movewindow, d"
    ];

    input = {
      kb_layout = "us";
      # kb_variant = null;
      # kb_model = null;
      kb_options = "ctrl:nocaps";
      # kb_rules = null;
      repeat_rate = 30;
      repeat_delay = 250;
      numlock_by_default = true;

      follow_mouse = 1;
      mouse_refocus = false;

      touchpad = {
        natural_scroll = true;
        tap-and-drag = true;
      };

      sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
    };

    cursor = {
      hide_on_key_press = true;
    };

    general = {
      gaps_in = 4;
      gaps_out = 7;
      border_size = 0;
      # col.active_border = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      # col.inactive_border = "rgba(595959aa)";
      resize_on_border = true;
      extend_border_grab_area = 15;
      hover_icon_on_border = true;

      layout = "dwindle";
    };

    decoration = {
      active_opacity = 0.90;
      inactive_opacity = 0.80;
      fullscreen_opacity = 1.0;
      dim_inactive = false;
      dim_strength = 0.1;
      dim_special = 0.4;

      rounding = 7;
      blur = {
        enabled = true;
        size = 5;
        passes = 2;
        new_optimizations = true;
        ignore_opacity = true;
        xray = false;
      };
    };

    animations = {
      enabled = true;

      bezier = [
        "myBezier, 0.05, 0.9, 0.1, 1.05"
        "overshot, 0.05, 0.9, 0.1, 1.1"
      ];

      animation = [
        "windows, 1, 5, overshot"
        "windowsOut, 1, 50, overshot"
        "border, 0, 10, default"
        "borderangle, 0, 8, default"
        "fade, 1, 7, overshot"
        "workspaces, 1, 6, overshot"
        "specialWorkspace, 1, 6, overshot, slidevert"
      ];
    };

    dwindle = {
      pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
      preserve_split = true; # you probably want this
      force_split = 2;
    };

    gestures = {
      workspace_swipe = false;
    };

    misc = {
      mouse_move_enables_dpms = true;
      key_press_enables_dpms = true;
      animate_manual_resizes = true;
      animate_mouse_windowdragging = true;

      enable_swallow = false;
      swallow_regex = "^(Alacritty)$";

      disable_hyprland_logo = true;
    };

  };
}
