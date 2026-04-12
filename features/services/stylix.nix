{ inputs, ... }:
{
  flake.modules.nixos.stylix = {
    imports = [ ../../modules/system/stylix.nix ];

    config.modules.stylix.enable = true;
  };

  flake.modules.homeManager.stylix = {
    imports = [
      (
        inputs.stylix.homeModules.stylix
        or inputs.stylix.homeModules.default
        or inputs.stylix.homeManagerModules.stylix
        or inputs.stylix.homeManagerModules.default
      )
    ];
  };
}
