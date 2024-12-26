_:

{

  config.programs.direnv.config = {
    global.hide_env_diff = true;
    whitelist.prefix = [ "~/.config/nix" ];
  };
}
