{ inputs, ... }:

{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";

  flake.modules.homeManager.comma =
    { config, ... }:
    {
      imports = [
        inputs.nix-index-database.homeModules.nix-index
      ];

      config = {
        persist.files = [ "${config.xdg.stateHome}/comma-choices" ];

        programs = {
          nix-index.enable = true;
          nix-index-database.comma.enable = true;
        };
      };
    };
}
