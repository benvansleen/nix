{ inputs, ... }:

{
  flake.modules.homeManager.cli =
    { osConfig, lib, ... }:
    {
      imports =
        with inputs.self.modules.homeManager;
        [
          git
          opencode
          tmux
          zsh
        ]
        ++ lib.optionals osConfig.machine.desktop [
          # alacritty
          direnv
          ghostty
          nushell
        ];

      config = {
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
          starship.enable = true;
        };
      };
    };
}
