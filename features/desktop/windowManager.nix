{ inputs, ... }:
{
  flake-file.inputs.hyprbar = {
    url = "github:benvansleen/hyprbar";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
      pre-commit-hooks.follows = "pre-commit-hooks";
    };
  };

  flake.modules.homeManager.windowManager = {
    imports = [
      ../../modules/home/window-manager
      (inputs.hyprbar.homeManagerModules.default or inputs.hyprbar.homeManagerModules.hyprbar)
    ];

    config.modules.window-manager.enable = true;
  };
}
