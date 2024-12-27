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

        "focus-follows-mouse = true"

        "clipboard-trim-trailing-spaces = true"
      ];
    };
  };
}
