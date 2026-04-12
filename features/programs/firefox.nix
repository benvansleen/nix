_: {
  flake.modules.nixos.firefox = {
    imports = [ ../../modules/system/firefox.nix ];

    config.modules.firefox.enable = true;
  };

  flake.modules.homeManager.firefox = {
    imports = [ ../../modules/home/firefox.nix ];

    config.modules.firefox.enable = true;
  };
}
