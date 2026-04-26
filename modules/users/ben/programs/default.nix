{ self, ... }:

{
  flake.modules.homeManager.ben-programs = {
    imports = with self.modules.homeManager; [
      ben-emacs
      ben-ghostty
      ben-nvim
    ];
  };
}
