{ inputs, ... }:
{
  flake.modules.homeManager.ben-cli = {
    imports = with inputs.self.modules.homeManager; [
      cli
      ben-starship
      ben-television
      ben-zsh
    ];
  };
}
