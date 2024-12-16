{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.features.cli;
in
{
  imports = [
    ./alacritty.nix
    ./zsh.nix
  ];

  options.features.cli = {
    enable = mkEnableOption "cli";
  };

  config = mkIf cfg.enable {
    features.alacritty.enable = true;
    features.zsh.enable = true;

    home.packages = with pkgs; [
      pipr
    ];

    programs.readline = {
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

    programs.broot = {
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

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global.hide_env_diff = true;
        whitelist.prefix = [ "~/.config/nix" ];
      };
    };

  };
}
