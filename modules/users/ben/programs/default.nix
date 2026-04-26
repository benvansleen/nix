{ inputs, ... }:
{
  flake.modules.homeManager.ben-programs = {
    imports = with inputs.self.modules.homeManager; [
      ben-emacs
      ben-ghostty
      ben-nvim
    ];
  };
}
