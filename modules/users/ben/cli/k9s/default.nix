{
  flake.modules.homeManager.k9s = {
    programs.k9s = {
      enable = true;
      skins = {
        gruvbox = ./gruvbox.yaml;
      };
      settings.k9s = {
        ui = {
          enableMouse = false;
          headless = true;
          logoless = true;
          reactive = true;
        };
        skipLatestRevCheck = true;
        logger = {
          fullScreen = true;
        };
      };
    };
  };
}
