{ inputs, ... }:

{
  flake.modules.homeManager.ben-windowManager = {
    imports = with inputs.self.modules.homeManager; [
      ben-hyprland
      centerpiece
      windowManager
    ];
  };
}
