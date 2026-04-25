{
  flake.modules.homeManager.direnv = {
    config = {
      persist.directories = [ "@data@/direnv" ];

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
