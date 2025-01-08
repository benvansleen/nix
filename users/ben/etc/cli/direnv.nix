{
  config = {
    modules.impermanence.persistedDirectories = [ "@data@/direnv" ];

    programs.direnv.config = {
      global.hide_env_diff = true;
      whitelist.prefix = [ "~/.config/nix" ];
    };
  };
}
