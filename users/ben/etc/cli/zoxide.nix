{ config, lib, ... }:

let
  inherit (lib) mkIf;
in
{
  config = mkIf config.programs.zoxide.enable {
    modules.home.impermanence.persistedDirectories = [ "@data@/zoxide" ];

    programs.zsh.shellAliases = mkIf config.programs.zoxide.enableZshIntegration {
      cd = "z";
    };
  };
}
