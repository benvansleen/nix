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
    mkDefault
    getExe
    ;
  cfg = config.modules.cli.nushell;
in
{
  options.modules.cli.nushell = {
    enable = mkEnableOption "nushell";
  };

  config = mkIf cfg.enable {
    modules = {
      cli = {
        starship.enable = mkDefault true;
        television = {
          enable = mkDefault true;
          enableNushellIntegration = true;
        };
      };
      impermanence.persistedFiles = [
        "@config@/nushell/history.sqlite3"
      ];
    };
    programs = {
      atuin = {
        enable = true;
        enableNushellIntegration = true;
      };
      broot.enableNushellIntegration = true;
      carapace = {
        enable = true;
        enableNushellIntegration = true;
      };
      direnv.enableNushellIntegration = true;
      eza = {
        enable = true;
        enableNushellIntegration = false;
        git = true;
        icons = "auto";
      };
      starship.enableNushellIntegration = mkIf config.modules.cli.starship.enable true;
      zoxide = {
        enable = true;
        enableNushellIntegration = true;
      };

      nushell = {
        enable = true;
        plugins = with pkgs.nushellPlugins; [
          # formats
          # gstat
          # polars
          # query
          # skim
          # units
        ];
        shellAliases = with pkgs; {
          cd = mkIf config.programs.zoxide.enableNushellIntegration "z";
          sudo = mkIf (lib.constants.privilege-escalation == "doas") "doas";

          htop = "${getExe bottom} -b";
          # ps = "${getExe procs}";
          grep = "${getExe ripgrep}";
          # find = "${getExe fd}fd";
          cat = "${getExe bat}";
          tree = "${getExe eza} --tree";
          # du = "${getExe dust}";
        };

        envFile.text = ''
          $env.PROMPT_INDICATOR_VI_INSERT = " "
          $env.PROMPT_INDICATOR_VI_NORMAL = "  "
        '';
        settings = {
          edit_mode = "vi";
          cursor_shape = {
            vi_insert = "blink_line";
            vi_normal = "blink_block";
          };

          use_ansi_coloring = "auto";
          use_kitty_protocol = true;

          completions = {
            algorithm = "prefix";
            sort = "smart";
            quick = true;
            partial = true;
            use_ls_colors = true;
            external = {
              enable = true;
              max_results = 50;
            };
          };

          history = {
            file_format = "sqlite";
            max_size = 5000000;
            isolation = true;
            sync_on_enter = true;
          };

          show_banner = false;
          error_style = "fancy";
          display_errors.exit_code = true;
          display_errors.termination_signal = true;
          footer_mode = "auto";
          table.mode = "compact_double";
        };

        configFile.text = /* nu */ ''
          $env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge {
              "XDG_DATA_DIRS": {
                  from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
                  to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
              }
          }

          $env.config.menus ++= [{
              name: help_menu
              only_buffer_difference: true # Search is done on the text written after activating the menu
              marker: "? "                 # Indicator that appears with the menu is active
              type: {
                  layout: description      # Type of menu
                  columns: 4               # Number of columns where the options are displayed
                  col_width: 20            # Optional value. If missing all the screen width is used to calculate column width
                  col_padding: 2           # Padding between columns
                  selection_rows: 4        # Number of rows allowed to display found options
                  description_rows: 10     # Number of rows allowed to display command description
              }
              style: {
                  text: green                   # Text style
                  selected_text: green_reverse  # Text style for selected option
                  description_text: yellow      # Text style for description
              }
          }]

          $env.config.menus ++= [{
              name: completion_menu
              only_buffer_difference: false # Search is done on the text written after activating the menu
              marker: "| "                  # Indicator that appears with the menu is active
              type: {
                  layout: columnar          # Type of menu
                  columns: 4                # Number of columns where the options are displayed
                  col_width: 20             # Optional value. If missing all the screen width is used to calculate column width
                  col_padding: 2            # Padding between columns
              }
              style: {
                  text: green                   # Text style
                  selected_text: green_reverse  # Text style for selected option
                  description_text: yellow      # Text style for description
              }
          }]


          $env.config.keybindings ++= [
            {
              name: help_menu
              modifier: none
              keycode: f1
              mode: [emacs, vi_insert, vi_normal]
              event: { send: menu name: help_menu }
            }

            {
              name: accept_hint
              modifier: alt
              keycode: Char_u00003b  # semicolon
              mode: [emacs, vi_insert, vi_normal]
              event: { send: HistoryHintComplete }
            }
            {
              name: accept_partial_hint
              modifier: alt
              keycode: Char_u00003a  # colon
              mode: [emacs, vi_insert, vi_normal]
              event: { send: HistoryHintWordComplete }
            }
          ]


          # fish-like abbreviations
          # from https://github.com/nushell/nushell/issues/5597
          let abbrs = {
            q: 'exit'
            cls: 'clear'
            g: 'git'
            gs: 'git status'
            gc: 'git commit'
            gp: 'git push'
            sys: 'systemctl'
            sysu: 'systemctl --user'
          }
          $env.config.keybindings ++= [
            {
              name: abbr_menu
              modifier: none
              keycode: enter
              mode: [emacs, vi_normal, vi_insert]
              event: [
                { send: menu name: abbr_menu }
                { send: enter }
              ]
            }
            {
              name: abbr_menu
              modifier: none
              keycode: space
              mode: [emacs, vi_normal, vi_insert]
              event: [
                { send: menu name: abbr_menu }
                { edit: insertchar value: ' ' }
              ]
            }
          ]
          $env.config.menus ++= [
            {
              name: abbr_menu
              only_buffer_difference: false
              marker: none
              type: {
                layout: columnar
                columns: 1
                col_width: 20
                col_padding: 2
              }
              style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
              }
              source: { |buffer, position|
                let match = $abbrs | columns | where $it == $buffer
                if ($match | is-empty) {
                  { value: $buffer }
                } else {
                  { value: ($abbrs | get $match.0) }
                }
              }
            }
          ]
          # end fish-like abbreviations
        '';
        extraConfig = /* nu */ ''
          $env.config.color_config.shape_external = { fg: "#89b482", attr: b}
          $env.config.color_config.shape_externalarg = { fg: "#a9b665" }
        '';
      };
    };
  };
}
