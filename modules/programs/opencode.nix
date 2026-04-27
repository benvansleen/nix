{
  flake.modules.homeManager.opencode =
    { config, lib, ... }:
    {
      config = {
        programs.opencode = {
          enable = true;
          settings = {
            autoupdate = false;
          };
          tui = {
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
