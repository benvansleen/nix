{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption mkDefault;
  cfg = config.modules.home.cli.zsh;
in
{
  options.modules.home.cli.zsh = {
    enable = mkEnableOption "zsh";
  };

  config = mkIf cfg.enable {
    modules.home.cli.starship.enable = mkDefault true;

    programs = {
      atuin = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          style = "compact";
          keymap_mode = "vim-insert";
          enter_accept = true;
          prefers_reduced_motion = true;
          search_mode = "skim";
          search_mode_shell_up_key_binding = "skim";
          update_check = false;
          auto_sync = false;
        };
      };

      broot.enableZshIntegration = true;

      direnv.enableZshIntegration = true;

      eza = {
        enable = true;
        enableZshIntegration = true;
        git = true;
        icons = "auto";
      };

      fzf = {
        enable = true;
        enableZshIntegration = false;
      };

      starship.enableZshIntegration = mkIf config.modules.home.cli.starship.enable true;

      zsh = {
        enable = true;
        autocd = true;
        autosuggestion.enable = true;
        defaultKeymap = "viins";

        history = {
          expireDuplicatesFirst = true;
          ignoreSpace = true;
          ignoreAllDups = true;
          size = 10000;
          share = false;
          path = "${config.xdg.dataHome}/zsh/history";
        };

        plugins = [
          # {
          # 	name = "zsh-vi-mode";
          # 	src = pkgs.fetchFromGitHub {
          # 	  repo = "zsh-vi-mode";
          # 	  owner = "jeffreytse";
          # 	  rev = "v0.11.0";
          # 	  hash = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
          # 	};
          # }

          {
            name = "fzf-tab-completion";
            file = "zsh/fzf-zsh-completion.sh";
            src = pkgs.fetchFromGitHub {
              owner = "lincheney";
              repo = "fzf-tab-completion";
              rev = "5ff8ab0f71006662fd3a7ab774a6cd837cdff32d";
              hash = "sha256-T7BocqbLIrEdaVZ5+5sOqP7NTc7hWmUU2EiicpKPZ0Y=";
            };
          }

        ];

        sessionVariables = {
          WORDCHARS = "*?_-.[]~=&;!#$%^(){}<>";
        };

        syntaxHighlighting = {
          enable = true;
          styles = {
            default = "fg=250";
            unknown-token = "fg=none";
            reserved-word = "fg=108";
            alias = "fg=blue,bold";
            builtin = "fg=blue,bold";
            command = "fg=blue,bold";
            precommand = "fg=069";
            path = "fg=white,italic";
            history-expansion = "fg=222";
            comment = "fg=245,italic";
            single-hyphen-option = "fg=250";
            double-hyphen-option = "fg=250";
            back-quoted-argument = "fg=250";
            back-double-quoted-argument = "fg=033";
            single-quoted-argument = "fg=173";
            double-quoted-argument = "fg=173";
            dollar-quoted-argument = "fg=140";
            dollar-double-quoted-argument = "fg=140";
            back-dollar-quoted-argument = "fg=140";
            bracket-level-1 = "fg=250";
            bracket-level-2 = "fg=250";
            cursor-matchingbracket = "fg=237,bold,bg=74";
          };
        };

        initExtraFirst = ''
          # zsh-vi-mode overwrites C-k for scrolling up history
          function zvm_before_lazy_keybindings() {
               bindkey -M viins '^k' up-history
          }
          function zvm_after_lazy_keybindings() {
               bindkey -M viins '^k' up-history
          }
          ZVM_LAZY_KEYBINDINGS=false

          bindkey -M viins jj vi-cmd-mode
        '';

        initExtra = ''
          bindkey '^I' fzf_completion
          zstyle ':completion:*' fzf-search-display true
          zstyle ':completion::*:git::git,add,*' fzf-completion-opts --preview='git -c color.status=always status --short'

          ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
          ZVM_VI_INSERT_ESCAPE_BINDKEY=jj
          ZVM_SURROUND_BINDKEY=classic


          bindkey -M viins '^[;' autosuggest-accept
          bindkey -M viins '^[:' forward-word
          function up_dir() {
              zle kill-whole-line
              cd ..
              zle end-of-line
              zle accept-line
          }
          function last_dir() {
              zle kill-whole-line
              cd - >/dev/null
              zle end-of-line
              zle accept-line
          }
          zle -N up_dir
          zle -N last_dir
          bindkey -M viins '^[^H' up_dir
          bindkey -M viins '^[^L' last_dir

          echo -ne '\e[3 q' # Use underscore shape cursor on startup.
          bindkey -M viins '^[l' delete-char
          bindkey -M viins '^[h' backward-delete-char
          bindkey -M viins '^h' backward-delete-word
          bindkey -M viins '^k' up-history
          bindkey -M viins '^j' down-history
          bindkey -M viins '^[f' open_emacs_find_file
          bindkey -M viins '^[r' open_emacs_recent_file
          bindkey -M viins '^[g' open_magit_here
          bindkey -M viins '^[e' zvm_vi_edit_and_fix_cursor
          WORDCHARS='*?-.[]~=&;!#$%^(){}<>'

          unsetopt BEEP
          setopt extendedglob
          setopt nomatch
          setopt menucomplete
          setopt interactivecomments
        '';

        loginExtra = ''
          if [[ $(echo $TTY | sed 's/[0-9]//g') = "/dev/tty" ]]
          then
              OLD_PROMPT=$(echo $PROMPT)
              export PROMPT=$(echo $OLD_PROMPT | sed 's/)/ | sed "s\/\/>\/g")/')
          fi
        '';

        shellAliases = {
          # by default, nixpkgs#<pkg> is a zsh glob pattern
          nix = "noglob nix";

          os-rebuild-test = ''
            ${pkgs.nh}/bin/nh os test ${config.xdg.configHome}/nix
          '';
          os-rebuild = ''
            ${pkgs.nh}/bin/nh os switch ${config.xdg.configHome}/nix
          '';

          htop = "${pkgs.bottom}/bin/btm -b";
          ps = "${pkgs.procs}/bin/procs";
          grep = "${pkgs.ripgrep}/bin/rg";
          find = "${pkgs.fd}/bin/fd";
          cat = "${pkgs.bat}/bin/bat";
          tree = "${pkgs.eza}/bin/eza --tree";
        };

        zsh-abbr = mkIf pkgs.config.allowUnfree {
          enable = true;
          abbreviations = {
            q = "exit";
            cls = "clear";
            ga = "git add";
            gs = "git status";
            gc = "git commit";
            gp = "git push";
            gr = "git restore";
            sys = "systemctl";
            sysu = "systemctl --user";
          };
        };

      };
    };
  };

}
