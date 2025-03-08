{ config, lib, ... }:

let
  inherit (lib) mkIf;
in
{
  config.modules.cli.ghostty = {
    settings = {
      useStylixTheme = true;
      options = {
        command = mkIf config.modules.cli.tmux.enable "tmux new-session -A -s master";
        confirm-close-surface = mkIf config.modules.cli.tmux.enable "false";
        app-notifications = mkIf config.modules.cli.tmux.enable "no-clipboard-copy";

        # Prevent "Xc x Yr" popup on each new surface
        resize-overlay = "never";

        # No titles or tab bars! Clean window only!
        window-decoration = "false";

        window-padding-x = "20";
        window-padding-y = "10";

        window-vsync = "false";

        bold-is-bright = "false";

        # "font-family = Hack"
        # "theme = gruvbox-material"
        font-size = toString config.stylix.fonts.sizes.terminal;
        font-feature = "+calt +liga +dlig";

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

        # C-c copies to cliboard IFF there is text available
        # to copy. Otherwise, pass C-c to process
        "performable:ctrl+c" = "copy_to_clipboard";
      };
    };
  };
}
