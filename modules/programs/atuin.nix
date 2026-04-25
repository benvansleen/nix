{
  flake.modules.homeManager.atuin =
    { config, ... }:
    {
      config = {
        persist.directories = [ "${config.xdg.dataHome}/atuin" ];

        programs.atuin.settings = {
          style = "auto";
          keymap_mode = "vim-insert";
          enter_accept = true;
          prefers_reduced_motion = true;
          search_mode = "skim";
          search_mode_shell_up_key_binding = "skim";
          update_check = false;
          auto_sync = false;
        };
      };
    };
}
