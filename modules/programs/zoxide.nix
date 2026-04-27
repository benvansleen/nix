{
  flake.modules.homeManager.zoxide =
    { config, lib, ... }:

    let
      inherit (lib) mkIf;
    in
    {
      config = mkIf config.programs.zoxide.enable {
        persist.directories = [ "${config.xdg.dataHome}/zoxide" ];

        programs.zsh.shellAliases = mkIf config.programs.zoxide.enableZshIntegration {
          cd = "z";
        };
      };
    };
}
