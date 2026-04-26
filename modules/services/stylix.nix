{ inputs, ... }:
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
      systems.follows = "systems";
    };
  };

  flake.modules.nixos.stylix =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      stylix = {
        enable = true;
        autoEnable = true;
        homeManagerIntegration.autoImport = false;
        image = ../users/ben/wallpapers/pensacola-beach-dimmed.png;
        polarity = "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-hard.yaml";
        fonts = with pkgs; {
          serif = {
            package = iosevka;
            name = "Iosevka Etoile";
          };
          sansSerif = {
            package = nerd-fonts.fira-code;
            name = "Fira Code";
          };
          monospace = {
            package = nerd-fonts.victor-mono;
            name = "Victor Mono";
          };
        };
      };
    };

  flake.modules.homeManager.stylix = {
    imports = [
      (inputs.stylix.homeModules.stylix or inputs.stylix.homeModules.default
        or inputs.stylix.homeManagerModules.stylix or inputs.stylix.homeManagerModules.default
      )
    ];
  };
}
