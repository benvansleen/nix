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

      zoxide = {
        enable = true;
        enableZshIntegration = true;
      };

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

        # Remove glyphs from prompt when not in a graphical terminal
        loginExtra = ''
          if [[ $(echo $TTY | sed 's/[0-9]//g') = "/dev/tty" ]]
          then
              OLD_PROMPT=$(echo $PROMPT)
              export PROMPT=$(echo $OLD_PROMPT | sed 's/)/ | sed "s\/\/>\/g")/')
          fi
        '';
      };
    };
  };

}
