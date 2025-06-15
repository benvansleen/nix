{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  inherit (lib)
    mkIf
    mkBefore
    mkAfter
    mkMerge
    ;
  flake = "${config.xdg.configHome}/nix";

  early-init = mkBefore ''
    # zsh-vi-mode overwrites C-k for scrolling up history
    function zvm_before_lazy_keybindings() {
         bindkey -M viins '^k' up-history
    }
    function zvm_after_lazy_keybindings() {
         bindkey -M viins '^k' up-history
    }
    ZVM_LAZY_KEYBINDINGS=false

    bindkey -M viins jj vi-cmd-mode

    # Change cursor shape for different vi modes.
    function zle-keymap-select {
      if [[ ''${KEYMAP} == vicmd ]] ||
         [[ ''$1 = 'block' ]]; then
        echo -ne '\e[1 q'

      elif [[ ''${KEYMAP} == main ]] ||
           [[ ''${KEYMAP} == viins ]] ||
           [[ ''${KEYMAP} = "" ]] ||
           [[ ''$1 = 'beam' ]]; then
        echo -ne '\e[5 q'
      fi
      starship_zle-keymap-select
    }
    zle -N zle-keymap-select
  '';

  late-init = mkAfter ''
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
    setopt nomatch
    setopt menucomplete
    setopt interactivecomments

    # Use beam shape cursor on startup.
    echo -ne '\e[5 q'
    preexec() {
        echo -ne '\e[5 q'
    }

    autoload -Uz surround
    zle -N delete-surround surround
    zle -N change-surround surround
    zle -N add-surround surround
    bindkey -a cs change-surround
    bindkey -a ds delete-surround
    bindkey -a ys add-surround
    bindkey -M visual S add-surround
  '';
in
{
  config = {
    modules.impermanence.persistedFiles = [ "@data@/zsh/history" ];

    programs.zsh = {
      shellAliases =
        with lib;
        with pkgs;
        {
          "nh search" = "nh search --flake ${flake}";
          os-rebuild-test = ''
            ${getExe nh} os test ${flake}
          '';
          os-rebuild = ''
            ${getExe nh} os switch ${flake}
          '';

          htop = "${getExe bottom} -b";
          ps = "${getExe procs}";
          grep = "${getExe ripgrep}";
          find = "${getExe fd}fd";
          cat = "${getExe bat}";
          tree = "${getExe eza} --tree";
          du = "${getExe dust}";
        };

      zsh-abbr = mkIf osConfig.machine.allowUnfree {
        enable = true;
        package = pkgs.unfree.zsh-abbr;
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

      initContent = mkMerge [
        early-init
        late-init
      ];
    };
  };
}
