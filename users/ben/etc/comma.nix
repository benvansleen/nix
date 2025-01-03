{ nix-index-database, ... }:

{
  imports = [
    nix-index-database.hmModules.nix-index
  ];

  config = {
    modules.home.impermanence.persistedFiles = [ "@state@/comma-choices" ];

    programs = {
      nix-index.enable = true;
      nix-index-database.comma.enable = true;
    };
  };
}
