_: {
  flake.modules.nixos.impermanence = {
    imports = [ ../../modules/system/impermanence.nix ];

    config.modules.impermanence.enable = true;
  };

  flake.modules.homeManager.impermanence = {
    imports = [ ../../modules/home/impermanence.nix ];
  };
}
