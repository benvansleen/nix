{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf;
in
{
  config = {
    xdg.configFile = {
      "ghostty/shaders" = {
        source = builtins.fetchGit {
          url = "https://github.com/hackr-sh/ghostty-shaders";
          rev = "3d7e56a3c46b2b6ba552ee338e35dc52b33042fa"; # 7/14/25
        };
      };
      "ghostty/retro-terminal-amber.glsl".text = ''
        float warp = 0.0; // simulate curvature of CRT monitor
        float scan = 0.50; // simulate darkness between scanlines

        void mainImage(out vec4 fragColor, in vec2 fragCoord)
        {
            // squared distance from center
            vec2 uv = fragCoord / iResolution.xy;
            vec2 dc = abs(0.5 - uv);
            dc *= dc;

            // warp the fragment coordinates
            uv.x -= 0.5; uv.x *= 1.0 + (dc.y * (0.3 * warp)); uv.x += 0.5;
            uv.y -= 0.5; uv.y *= 1.0 + (dc.x * (0.4 * warp)); uv.y += 0.5;

            // sample inside boundaries, otherwise set to black
            if (uv.y > 1.0 || uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0)
                fragColor = vec4(0.0, 0.0, 0.0, 1.0);
            else
            {
                // determine if we are drawing in a scanline
                float apply = abs(sin(fragCoord.y) * 0.5 * scan);

                // sample the texture and apply a teal tint
                vec3 color = texture(iChannel0, uv).rgb;
                vec3 amberTint = vec3(0.9, 0.5, 0.0); // amber color (slightly more green than blue)

                // mix the sampled color with the amber tint based on scanline intensity
                fragColor = vec4(mix(color * amberTint, vec3(0.0), apply), 1.0);
            }
        }
      '';
    };
  };

  config.modules.cli.ghostty = {
    settings = {
      useStylixTheme = true;
      custom-shaders = [
        "./retro-terminal-amber.glsl"
        "./shaders/bettercrt.glsl"
      ];
      options = {
        command = mkIf config.modules.cli.tmux.enable "tmux-attach-to-last-session";
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

        font-family = "3270";
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

        # C-c copies to clipboard IFF there is text available
        # to copy. Otherwise, pass C-c to process
        "performable:ctrl+c" = "copy_to_clipboard";
      };
    };
  };
}
