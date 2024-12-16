{
  globals,
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home.cli;
in
globals.importAll lib ./.
// {

  options.modules.home.cli = {
    enable = mkEnableOption "cli";
  };

  config = mkIf cfg.enable {
    modules.home.cli = {
      alacritty.enable = true;
      zsh.enable = true;
    };

    home.packages = with pkgs; [
      pipr
    ];

    programs = {
      readline = {
        enable = true;
        bindings = { };
        extraConfig = ''
            set editing-mode vi
          set keymap vi-command
          set bell-style none
          $if mode=vi
            set keymap vi-command
            "gg": beginning-of-history
            "G": end-of-history
            set keymap vi-insert
            "jj": vi-movement-mode
            "\C-h": backward-kill-word
            "\C-k": previous-history
            "\C-j": next-history
            "\C-l": clear-screen
          $endif
        '';
      };

      broot = {
        enable = true;
        settings = {
          modal = true;
          verbs = [
            {
              key = ";";
              execution = ":mode_input";
            }
            {
              key = "q";
              execution = ":quit";
            }
          ];
        };
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          global.hide_env_diff = true;
          whitelist.prefix = [ "~/.config/nix" ];
        };
      };
    };
  };
}
