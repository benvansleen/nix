{ inputs, ... }:
{
  flake.modules.homeManager.ben-cli =
    { osConfig, lib, ... }:
    {
      imports =
        with inputs.self.modules.homeManager;
        [
          cli
          comma
          atuin
          opencode
          tmux
          zoxide
          zsh

          ben-starship
          ben-television
          ben-zsh
        ]
        ++ lib.optionals osConfig.machine.desktop [
          direnv
          nushell
        ];
    };
}
