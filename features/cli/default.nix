{ pkgs, ... }:

{
  imports = [
    ./terminal.nix
    ./zsh.nix
  ];

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
		{ key = ";"; execution = ":mode_input"; }
		{ key = "q"; execution = ":quit"; }
	  ];
    };

  };
}
