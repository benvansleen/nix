{ inputs, ... }:
{
  flake.modules.homeManager.ben-programs = {
    imports = with inputs.self.homeModules; [
      ben-emacs
      ben-ghostty
      ben-nvim
    ];
  };
}
