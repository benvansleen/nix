_: {
  flake.modules.nixos.firefox = {
    config.modules.firefox.enable = true;
  };

  flake.modules.homeManager.firefox = {
    config.modules.firefox.enable = true;
  };
}
