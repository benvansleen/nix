{
  flake.modules.homeManager.git = {
    config = {
      programs = {
        git = {
          enable = true;
          settings.init.defaultBranch = "master";
          signing.format = "openpgp";
        };
        difftastic = {
          enable = true;
          git.enable = true;
          options = {
            color = "auto";
            display = "side-by-side";
            background = "dark";
          };
        };
      };
    };
  };
}
