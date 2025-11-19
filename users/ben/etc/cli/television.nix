{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.cli.television;
  toToml = (pkgs.formats.toml { }).generate;
  cable-dir = ".config/television/cable/";
in
{
  options.modules.cli.television = {
    enable = mkEnableOption "television";
    enableNushellIntegration = mkEnableOption "television nushell integration";
  };
  config = mkIf cfg.enable {
    programs = {
      television.enable = true;
      nix-search-tv = {
        enable = true;
        enableTelevisionIntegration = false;
      };
    };
    modules.impermanence.persistedDirectories = [
      "@config@/television/cable"
      "@cache@/nix-search-tv"
    ];
    home.file.".config/television/config.toml".source = toToml "television-config.toml" {
      tick_rate = 50;
      default_channel = "files";
      history_size = 200;
      global_history = false;
      ui = {
        ui_scale = 100;
        orientation = "landscape";
        theme = "default";
        input_bar = {
          position = "top";
          prompt = ">";
          border_type = "none";
        };
        status_bar = {
          separator_open = "";
          separator_close = "";
          hidden = true;
        };
        results_panel = {
          border_type = "none";
        };
        preview_panel = {
          size = 50;
          scrollbar = false;
          border_type = "rounded";
          hidden = false;
        };
        help_panel = {
          show_categories = true;
          hidden = true;
        };
        remote_control = {
          show_channel_descriptions = true;
          sort_alphabetically = true;
          disabled = false;
        };
      };
      keybindings = {
        esc = "quit";
        ctrl-c = "quit";

        down = "select_next_entry";
        ctrl-j = "select_next_entry";
        up = "select_prev_entry";
        ctrl-k = "select_prev_entry";
        ctrl-u = "scroll_preview_up";
        ctrl-d = "scroll_preview_down";

        ctrl-r = "reload_source";
        ctrl-s = "cycle_sources";

        ctrl-n = "toggle_remote_control";
        ctrl-o = "toggle_preview";
        "ctrl-/" = "toggle_help";
        ctrl-i = "toggle_status_bar";
        ctrl-l = "toggle_layout";

        backspace = "delete_prev_char";
        ctrl-h = "delete_prev_word";
        ctrl-a = "go_to_input_start";
        ctrl-e = "go_to_input_end";
      };
      events = {
        mouse-scroll-up = "scroll_preview_up";
        mouse-scroll-down = "scroll_preview_down";
      };
      shell_integration = {
        fallback_channel = "files";
        channel_triggers = {
          alias = [
            "alias"
            "unalias"
          ];
          env = [
            "export"
            "unset"
          ];
          dirs = [
            "cd"
            "ls"
            "rmdir"
          ];
          procs = [ "kill" ];
          files = [
            "cat"
            "bat"
            "less"
            "head"
            "tail"
            "vim"
            "vi"
            "nvim"
            "cp"
            "mv"
            "rm"
            "touch"
            "chmod"
            "chown"
            "ln"
            "tar"
            "zip"
            "unzip"
            "gzip"
            "gunzip"
            "xz"
          ];
          git-diff = [
            "git add"
            "git restore"
          ];
          git-branch = [
            "git checkout"
            "git branch"
            "git merge"
            "git rebase"
            "git pull"
            "git push"
          ];
          git-log = [
            "git log"
            "git show"
          ];
          docker-images = [
            "docker run"
            "podman run"
          ];
          git-repos = [
            "nvim"
            "git clone"
          ];
          nix = [ "nix" ];
        };
      };
    };
    programs.nushell.extraConfig = mkIf cfg.enableNushellIntegration /* nu */ ''
      def tv_smart_autocomplete [] {
           let line = (commandline)
           let cursor = (commandline get-cursor)
           let lhs = ($line | str substring 0..$cursor)
           let cmds = ($line | split row " " | where {|part| ($part | str length) > 0})

           let output = match $cmds {
               [] => { tv --inline exe }, 
               [_] => { tv --inline --autocomplete-prompt $lhs },
               [$hd, $path, ..] if ($path | path exists) => {
                   tv --inline --autocomplete-prompt $hd $path
               },
               [$hd, $path, ..] if (($path | str starts-with "..") or ($path | str starts-with "./")) => {
                   let final_sep = $path | str index-of -e "/"
                   let dir = $path | str substring ..$final_sep | path expand
                   let beg_input = "^" + ($path | str substring ($final_sep + 1)..) + " "
                   let final_offset = ($path | str length) - $final_sep - 1
                   tv --inline --autocomplete-prompt $hd --input $beg_input $dir
                     | str substring $final_offset..
               },
               [$hd, ..$rest] if not ($hd in ["nix" "git"]) => {
                   let remainder = $rest | str join " " | str downcase
                   tv --inline --autocomplete-prompt $hd --input ("^" + $remainder + " ") 
                     | str substring (($remainder | str length)..)
               },
               _ => { tv --inline --autocomplete-prompt $lhs },
           } | str trim

           if ($output | str length) > 0 {
               let rhs = ($line | str substring $cursor..)
               let result = $lhs + $output
               let new_line = $result + $rhs
               let new_cursor = ($result | str length)
               commandline edit --replace $new_line
               commandline set-cursor $new_cursor
           }
      }

      $env.config.keybindings ++= [
        {
          name: tv_completion
          modifier: none
          keycode: tab
          mode: [vi_normal, vi_insert, emacs]
          event: {
            send: executehostcommand
            cmd: "tv_smart_autocomplete"
          }
        }
        {
          name: builtin_completion
          modifier: Control
          keycode: char_n
          mode: [vi_normal vi_insert emacs]
          event: {
            until: [
              { send: menu name: completion_menu }
              { send: menunext }
              { edit: complete }
            ]
          }
        }
      ]
    '';

    home.file = {
      "${cable-dir}/nix.toml".source = toToml "television-cable-nix.toml" {
        metadata = {
          name = "nix";
          description = "Search nix options and packages";
          requirements = [ "nix-search-tv" ];
        };
        preview.command = "nix-search-tv preview '{}'";
        source = {
          command = "nix-search-tv print";
          output = ''{replace:s/\/ /#/|trim}'';
        };
      };
      "${cable-dir}/exe.toml".source = toToml "television-cable-exe.toml" {
        metadata = {
          name = "exe";
          description = "Search executables on $PATH";
          requirements = [ ];
        };
        preview.command = "man --no-subpages '{split:/:-1}' || true";
        source = {
          command = ''
            IFS=: read -ra dirs <<< "$PATH"
            for d in "''${dirs[@]}"; do
                for f in "$d"/*; do
                    [[ -f $f && -x $f ]] && printf '%s\n' "$f"
                done
            done
          '';
          output = ''{split:/:-1}'';
        };
      };
      "${cable-dir}/files.toml".source = toToml "television-cable-files.toml" {
        metadata = {
          name = "files";
          description = "A channel to select files and directories";
          requirements = [
            "fd"
            "bat"
          ];
        };
        source.command = [
          "fd -t f"
          "fd -t f -H"
        ];
        preview = {
          command = "bat -n --color=always '{}'";
          env = {
            BAT_THEME = "ansi";
          };
        };
        keybindings = {
          shortcut = "ctrl-f";
          ctrl-e = "actions:edit";
          # left = "actions:goto_parent_dir";
        };
        actions = {
          edit = {
            description = "Opens the selected entries with the default editor (falls back to vim)";
            command = "\${EDITOR:-vim} '{}'";
            mode = "execute";
          };
          goto_parent_dir = {
            description = "Re-opens tv in the parent directory";
            command = "tv files ..";
            mode = "execute";
          };
        };
      };
      "${cable-dir}/dirs.toml".source = toToml "television-cable-dirs.toml" {
        metadata = {
          name = "dirs";
          description = "A channel to select from directories";
          requirements = [ "fd" ];
        };
        source.command = [
          "fd -t d"
          "fd -t d -H"
        ];
        preview.command = "ls -la --color=always '{}'";
        # keybindings = {
        #   left = "actions:goto_parent_dir";
        # };
        # actions = {
        #   goto_parent_dir = {
        #     description = "Re-opens tv in the parent directory";
        #     command = "tv --source-output '{prepend:../}' dirs ..";
        #     mode = "execute";
        #   };
        # };
      };
    };
  };
}
