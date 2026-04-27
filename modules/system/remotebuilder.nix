{
  flake.modules.nixos.remotebuilder = {
    config = {
      nix.settings.trusted-users = [ "remotebuild" ];
      users.groups.remotebuild = { };
      users.users.remotebuild = {
        isSystemUser = true;
        group = "remotebuild";
        useDefaultShell = true;
      };
    };
  };
}
