{
  config = {
    nvim = {
      enable = true;
      packageDefinitions.replace = {
        nvim = _: {
          settings = {
            aliases = [
              "vim"
              "vi"
            ];
          };
        };
      };
    };

    modules.impermanence.persistedDirectories = [
      "@config@/nvim"
    ];
  };
}
