{
  flake-file.inputs = {
    opencode.url = "github:anomalyco/opencode";
  };

  flake.modules.homeManager.opencode =
    { config, lib, ... }:
    {
      config = {
        programs.opencode = {
          enable = true;
          settings = {
            autoupdate = false;
            theme = lib.mkForce "gruvbox"; # override stylix theme
          };
        };
        persist.directories = with config.xdg; [
          "${configHome}/opencode"
          "${stateHome}/opencode"
          "${dataHome}/opencode"
          "${cacheHome}/opencode"
        ];
      };
    };
}
