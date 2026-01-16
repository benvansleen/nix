{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  cfg = config.modules.remotebuilder;
in
{
  options.modules.remotebuilder = {
    enable = mkEnableOption "create user for remote builds";
  };

  config = mkIf cfg.enable {
    nix.settings.trusted-users = [ "remotebuild" ];
    users.groups.remotebuild = { };
    users.users.remotebuild = {
      isSystemUser = true;
      group = "remotebuild";
      useDefaultShell = true;
    };
  };
}
