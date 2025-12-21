{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.cli.opencode;
in
{
  options.modules.cli.opencode = {
    enable = mkEnableOption "opencode";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      settings = {
        autoupdate = false;
        theme = lib.mkForce "gruvbox"; # override stylix theme
      };
    };
    modules.impermanence.persistedDirectories = [
      "@config@/opencode"
      "@state@/opencode"
      "@data@/opencode"
      "@cache@/opencode"
    ];
  };
}
