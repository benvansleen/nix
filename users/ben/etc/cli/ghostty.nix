_:

{
  config = {
    modules.home.cli.ghostty = {
      enable = true;
      settings = [
        "window-padding-x = 20"
        "window-padding-y = 10"

        "window-decoration = false"
        "window-vsync = false"

        "bold-is-bright = true"

        # "font-family = Hack"
        "font-size = 14"
        "font-feature = +calt +liga +dlig"
        # "theme = gruvbox-material"

        "cursor-invert-fg-bg = true"
        "cursor-opacity = 0.7"
        "cursor-style-blink = true"
        "cursor-click-to-move = true"

        "link-url = true"

        "focus-follows-mouse = false"

        "clipboard-trim-trailing-spaces = true"

        "gtk-single-instance = true"

        "keybind = ctrl+alt+k=scroll_page_fractional:-0.15"
        "keybind = ctrl+alt+j=scroll_page_fractional:0.15"

        "keybind = ctrl+alt+i=inspector:toggle"

        "keybind = ctrl+w=close_surface"

        "keybind = ctrl+alt+t=new_tab"
        "keybind = ctrl+tab=next_tab"
        "keybind = ctrl+shift+tab=previous_tab"

        "keybind = ctrl+alt+p=new_split:right"
        "keybind = ctrl+alt+l=goto_split:right"
        "keybind = ctrl+alt+h=goto_split:left"

        "keybind = ctrl+alt+o=toggle_tab_overview"
      ];
    };
  };
}
