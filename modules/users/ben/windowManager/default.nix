{ self, ... }:

{
  flake.modules.homeManager.ben-windowManager = {
    imports = with self.modules.homeManager; [
      ben-hyprland
      centerpiece
      windowManager
    ];
  };
}
