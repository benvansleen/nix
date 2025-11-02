{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:

let
  inherit (osConfig.users.users.${config.home.username}) shell;
  inherit (lib) mkEnableOption mkIf optionals;
  cfg = config.modules.cli.tmux;
in
{
  options.modules.cli.tmux = {
    enable = mkEnableOption "tmux";
    enable-resurrect = mkEnableOption "tmux-resurrect";
  };
  config = mkIf cfg.enable {
    modules.impermanence.persistedDirectories = mkIf cfg.enable-resurrect [
      "@config@/tmux/resurrect"
    ];

    programs.tmux = mkIf cfg.enable {
      enable = true;
      terminal = "tmux-256color";
      historyLimit = 100000;
      baseIndex = 1;
      keyMode = "vi";
      mouse = true;
      newSession = false;
      plugins =
        with pkgs.tmuxPlugins;
        [
          better-mouse-mode
          sidebar
          {
            plugin = prefix-highlight;
            extraConfig = "set -g status-left '#{prefix_highlight}'";
          }
          {
            plugin = fingers;
            extraConfig = ''
              set -g @fingers-key F
              set -g @fingers-jump-key S
              set -g @fingers-keyboard-layout "qwerty-homerow"
            '';
          }
          {
            plugin = fuzzback;
            extraConfig = ''
              unbind /
              set -g @fuzzback-bind /
              set -g @fuzzback-popup 1
              set -g @fuzzback-hide-preview 1
              set -g @fuzzback-popup-size '90%'
            '';
          }
        ]
        ++ optionals cfg.enable-resurrect [
          {
            plugin = resurrect;
            extraConfig = ''
              set -g @resurrect-dir '~/.config/tmux/resurrect'
              set -g @resurrect-processes 'vi vim nvim emacs emacsclient man less more tail top htop btm ssh'
            '';
          }
        ];
      prefix = "C-Space";
      extraConfig = ''
        bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

        bind -r ";" command-prompt
        bind n new-window
        bind N new-session
        bind b choose-session

        bind-key | split-window -hc "''${pane_current_path}"
        bind-key -r '\' split-window -hc "''${pane_current_path}"
        bind-key - split-window -vc "''${pane_current_path}"

        bind Space last-window
        bind-key C-Space switch-client -l
        bind [ previous-window
        bind ] next-window
        bind k select-pane -U
        bind j select-pane -D
        bind h select-pane -L
        bind l select-pane -R


        ## For Navigator.nvim
        version_pat='s/^tmux[^0-9]*([.0-9]+).*/\1/p'
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
            | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        bind-key -n M-h if-shell "$is_vim" "send-keys M-h" "select-pane -L"
        bind-key -n M-j if-shell "$is_vim" "send-keys M-j" "select-pane -D"
        bind-key -n M-k if-shell "$is_vim" "send-keys M-k" "select-pane -U"
        bind-key -n M-l if-shell "$is_vim" "send-keys M-l" "select-pane -R"
        tmux_version="$(tmux -V | sed -En "$version_pat")"
        setenv -g tmux_version "$tmux_version"

        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

        bind-key -T copy-mode-vi M-h select-pane -L
        bind-key -T copy-mode-vi M-j select-pane -D
        bind-key -T copy-mode-vi M-k select-pane -U
        bind-key -T copy-mode-vi M-l select-pane -R
        bind-key -T copy-mode-vi M-\\ select-pane -l



        bind -n M-[ previous-window
        bind -n M-] next-window

        bind i next-layout
        bind -r "<" swap-window -d -t -1
        bind -r ">" swap-window -d -t +1

        bind f resize-pane -Z
        bind -r C-j resize-pane -D 10
        bind -r C-k resize-pane -U 10
        bind -r C-h resize-pane -L 10
        bind -r C-l resize-pane -R 10

        bind J choose-window 'join-pane -s "%%"'


        bind v copy-mode
        bind -T copy-mode-vi i send-keys -X cancel
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind -T copy-mode-vi C-k send-keys -X page-up
        bind -T copy-mode-vi C-j send-keys -X page-down

        set -g status off
        set-hook -g after-new-window      'if "[ #{session_windows} -gt 1 ]" "set-option -g status-style bg=default ; set status on"'
        set-hook -g after-kill-pane       'if "[ #{session_windows} -lt 2 ]" "set status off"'
        set-hook -g pane-exited           'if "[ #{session_windows} -lt 2 ]" "set status off"'
        set-hook -g window-layout-changed 'if "[ #{session_windows} -lt 2 ]" "set status off"'

        set-option -g status-interval 1
        set-option -g automatic-rename on
        set-option -g automatic-rename-format "#{?#{==:#{pane_current_command},${shell.NIX_MAIN_PROGRAM}},#{b:pane_current_path},#{pane_current_command}}"
        set -g status-justify centre

        set -g status-left-length 100
        set -g status-left-style default
        # set -g status-left " "

        set -g status-right-length 100
        set -g status-right-style default
        set -g status-right " "

        set -sg escape-time 5
      '';
    };

    home.packages = [
      (pkgs.writeShellApplication {
        name = "tmux-attach-to-last-session";
        text =
          let
            tmux-bin = lib.getExe pkgs.tmux;
          in
          ''
            if tmux info &> /dev/null; then
                function get_last_tmux_session() {
                    ${tmux-bin} list-sessions -F \
                      "#{session_created}|#{session_id}" \
                      | sort -r \
                      | head -n1 \
                      | cut -d'|' -f2
                }
                ${tmux-bin} attach-session -t "$(get_last_tmux_session)"
            else
                ${tmux-bin} new-session -A -s master
            fi
          '';
      })
    ];
  };
}
