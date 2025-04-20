{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.cli;
in
lib.importAll ./.
// {
  options.modules.cli = {
    enable = mkEnableOption "cli";
  };

  config = mkIf cfg.enable {
    modules.cli = {
      alacritty.enable = osConfig.machine.desktop;
      ghostty.enable = osConfig.machine.desktop;
      tmux = {
        enable = osConfig.machine.desktop;
        enable-resurrect = osConfig.machine.desktop;
      };
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

      broot.enable = true;

      direnv = {
        enable = osConfig.machine.desktop;
        nix-direnv.enable = true;
      };
    };
  };
}
