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

    home.file = {
      ".local/share/fennel-ls/docsets/nvim.lua".source = builtins.fetchurl {
        url = "https://git.sr.ht/~micampe/fennel-ls-nvim-docs/blob/main/nvim.lua";
        sha256 = "0k7qksd0h0yq4548jigh5ivp7hfyh3w8cj3gi5ycv6y0kw5r9dbh";
      };
    };

    modules.impermanence.persistedDirectories = [
      "@config@/nvim"
    ];
  };
}
