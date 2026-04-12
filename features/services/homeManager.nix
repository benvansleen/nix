_: {
  flake.modules.nixos.homeManager = {
    imports = [ ../../modules/system/home-manager.nix ];

    config.modules.home-manager.enable = true;
  };
}
