{
  flake.modules.homeManager.direnv =
    { config, ... }:
    {
      config = {
        persist.directories = [ "${config.xdg.dataHome}/direnv" ];

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
          config = {
            global.hide_env_diff = true;
            whitelist.prefix = [ "~/.config/nix" ];
          };
        };
      };
    };
}
