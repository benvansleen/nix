_: {
  flake.modules.homeManager.cli = {
    imports = [ ../../modules/home/cli ];

    config.modules.cli.enable = true;
  };
}
