{
  self,
  pkgs,
  osConfig,
  ...
}:

let
  # if-not-desktop = attr: if !osConfig.machine.desktop then attr else null;
  flake-outputs = "(builtins.getFlake ${self.outPath}).outputs.nixosConfigurations.${osConfig.machine.name}";
in
{
  config = {
    wrappers.neovim = {
      enable = true;
      settings = {
        nixdNixpkgsPath = "import ${pkgs.path} { }";
        nixdNixosPath = "${flake-outputs}.options";
        nixdHomeManagerPath = "${flake-outputs}.options.home-manager.users.type.getSubOptions [ ]";
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
      "@data@/nvim"
      "@state@/nvim"
    ];
  };
}
