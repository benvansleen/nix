{ inputs, ... }:

{
  flake-file.inputs.nvim = {
    url = "github:benvansleen/nvim/migrate-to-nix-wrapper-modules";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      pre-commit-hooks.follows = "pre-commit-hooks";
      treefmt-nix.follows = "treefmt-nix";
    };
  };

  flake.modules.homeManager.ben-nvim =
    {
      config,
      osConfig,
      pkgs,
      ...
    }:
    {
      imports = [
        (inputs.nvim.homeManagerModules.default or inputs.nvim.homeManagerModules.nvim)
      ];

      config =
        let
          flake-outputs = "(builtins.getFlake ${inputs.self.outPath}).outputs.nixosConfigurations.${osConfig.machine.name}";
        in
        {
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

          persist.directories = with config.xdg; [
            "${configHome}/nvim"
            "${dataHome}/nvim"
            "${stateHome}/nvim"
          ];
        };
    };
}
