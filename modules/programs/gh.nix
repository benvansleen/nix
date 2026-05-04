{
  flake.modules.homeManager.gh =
    { config, ... }:
    {
      persist.directories = [ "${config.xdg.configHome}/gh" ];
    };
}
