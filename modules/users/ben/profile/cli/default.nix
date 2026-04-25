{ inputs, ... }:
{
  flake.module.homeManager.ben-cli = {
    imports = with inputs.self.homeModules; [
      ben-starship
      ben-television
      ben-zsh
    ];
  };
}
