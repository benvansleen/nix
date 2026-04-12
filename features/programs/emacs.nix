_: {
  flake.modules.homeManager.emacs = {
    imports = [ ../../modules/home/emacs ];

    config.modules.emacs.enable = true;
  };
}
