_: {
  flake.modules.nixos.homeManager = {
    config.modules.home-manager.enable = true;
  };
}
