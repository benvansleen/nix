{ inputs, ... }:

{
  flake-file.inputs.nix-index-database = {
    url = "github:nix-community/nix-index-database";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.homeManager.comma = {
    imports = [
      inputs.nix-index-database.homeModules.nix-index
    ];

    config = {
      persist.files = [ "@state@/comma-choices" ];

      programs = {
        nix-index.enable = true;
        nix-index-database.comma.enable = true;
      };
    };
  };
}
