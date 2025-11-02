{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  inherit (config.modules.window-manager) terminal;
  plugin-isEnabled =
    plugin: lib.elem pkgs.hyprlandPlugins."${plugin}" config.wayland.windowManager.hyprland.plugins;

  direction = pkgs.writeShellApplication {
    name = "direction";
    text = ''
      ${./direction.sh} "$1"
    '';
    runtimeInputs = with pkgs; [
      jq
      hyprland
    ];
  };
  direction-bin = "${direction}/bin/direction";

  special-toggle = pkgs.writeShellScript "special-toggle" ''
    cur_ws=''$(
      ${pkgs.hyprland}/bin/hyprctl activewindow -j \
      | ${pkgs.jq}/bin/jq -r '.workspace | .name'
    )
    if [ "$cur_ws" = "special" ]; then
      new_ws="m+1"
    else
      new_ws="special"
    fi

    ${pkgs.hyprland}/bin/hyprctl dispatch movetoworkspace "$new_ws"
  '';
in
{
  config.wayland.windowManager.hyprland.settings = {
    ecosystem.no_update_news = true;
    env = [
      # "AQ_DRM_DEVICES,/dev/dri/card1"

      "HYPRCURSOR_THEME,${config.home.pointerCursor.name}"
      "HYPRCURSOR_SIZE,${toString config.home.pointerCursor.size}"

      "XDG_CURRENT_DESKTOP,Hyprland"
      "XDG_SESSION_TYPE,wayland"
      "GDK_BACKEND,wayland"
      "QT_QPA_PLATFORM,wayland"
    ];

    "$mainMod" = "SUPER";
    bind = [
      # "$mainMod, Return, exec, ${pkgs.alacritty}/bin/alacritty"
      "$mainMod, Return, exec, ${lib.getExe terminal}"
      # "$mainMod SHIFT, Return, exec, ~/.config/hypr/special-term"
      "$mainMod, E, exec, ghostty -e nvim"
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

      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"
      "$mainMod, h, exec, ${direction-bin} l"
      "$mainMod, l, exec, ${direction-bin} r"
      "$mainMod, k, exec, ${direction-bin} u"
      "$mainMod, j, exec, ${direction-bin} d"

      "$mainMod SHIFT, h, movewindow, l"
      "$mainMod SHIFT, l, movewindow, r"
      "$mainMod SHIFT, k, movewindow, u"
      "$mainMod SHIFT, j, movewindow, d"

      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"
      "$mainMod, TAB, focuscurrentorlast"
      "$mainMod, minus, togglespecialworkspace"
      "$mainMod SHIFT, minus, exec, ${special-toggle}"

      "$mainMod, bracketright, workspace, e+1"
      "$mainMod, bracketleft, workspace, e-1"

      "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
      "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
      "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
      "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
      "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
      "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
      "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
      "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
      "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
      "$mainMod SHIFT, 0, movetoworkspacesilent, 10"

      "$mainMod, SPACE, exec, ${pkgs.wofi}/bin/wofi --show drun"
    ]
    ++ lib.optionals (plugin-isEnabled "hyprexpo") [
      "$mainMod, grave, hyprexpo:expo, toggle"
    ];

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    input = {
      kb_layout = "us";
      kb_options = "ctrl:nocaps";
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
      resize_on_border = true;
      extend_border_grab_area = 15;
      hover_icon_on_border = true;

      layout = "dwindle";
    };

    decoration = {
      active_opacity = 0.9;
      inactive_opacity = 0.75;
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

    misc = {
      mouse_move_enables_dpms = true;
      key_press_enables_dpms = true;
      animate_manual_resizes = true;
      animate_mouse_windowdragging = true;

      enable_swallow = false;
      swallow_regex = "^(Alacritty)$";

      disable_hyprland_logo = true;
    };
  }
  // lib.optionalAttrs (osConfig.machine.name == "amd") (
    let
      left = "desc:LG Electronics BK550Y 009MXSK5P902";
      right = "desc:LG Electronics BK550Y 009MXAY5P912";
    in
    {
      monitor = [
        "${left}, 1920x1080, 0x0, 1, transform, 1"
        "${right}, 1920x1080, 1080x0, 1"
      ];
      workspace = [
        "1, monitor:${left}"
        "2, monitor:${left}"
        "3, monitor:${left}"
        "4, monitor:${left}"
        "5, monitor:${right}"
        "6, monitor:${right}"
        "7, monitor:${right}"
        "8, monitor:${right}"
        "9, monitor:${right}"
      ];

    }
  );
}
