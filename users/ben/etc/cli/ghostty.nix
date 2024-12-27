{
  config.modules.home.cli.ghostty = {
    enable = true;
    settings = {
      options = {
        window-padding-x = "20";
        window-padding-y = "10";

        window-decoration = "false";
        window-vsync = "false";

        bold-is-bright = "true";

        # "font-family = Hack"
        font-size = "14";
        font-feature = "+calt +liga +dlig";
        # "theme = gruvbox-material"

        cursor-invert-fg-bg = "true";
        cursor-opacity = "0.7";
        cursor-style-blink = "true";
        cursor-click-to-move = "true";

        link-url = "true";

        focus-follows-mouse = "false";

        clipboard-trim-trailing-spaces = "true";

        gtk-single-instance = "true";
      };

      keybinds = {
        "ctrl+alt+k" = "scroll_page_fractional:-0.15";
        "ctrl+alt+j" = "scroll_page_fractional:0.15";

        "ctrl+alt+i" = "inspector:toggle";

        "ctrl+w" = "close_surface";

        "ctrl+alt+t" = "new_tab";
        "ctrl+tab" = "next_tab";
        "ctrl+shift+tab" = "previous_tab";

        "ctrl+alt+p" = "new_split:right";
        "ctrl+alt+l" = "goto_split:right";
        "ctrl+alt+h" = "goto_split:left";

        "ctrl+alt+o" = "toggle_tab_overview";
      };
    };
  };
}
