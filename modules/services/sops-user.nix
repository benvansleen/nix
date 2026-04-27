{ inputs, self, ... }:

{
  flake.modules.nixos.sops-user =
    { config, lib, ... }:
    {
      imports = [ self.modules.nixos.sops ];

      options.modules.sops-user = with lib; {
        username = mkOption {
          type = types.str;
          description = "username of sops-user";
        };
      };

      config =
        let
          cfg = config.modules.sops-user;
          user = config.users.users.${cfg.username};
        in
        {
          home-manager.users.${cfg.username}.imports = [
            self.modules.homeManager.sops
            {
              sops = inputs.secrets.${cfg.username} "${user.home}/.ssh/master";
            }
          ];

          sops.secrets = {
            ssh_master_pem = {
              path = "${user.home}/.ssh/master";
              owner = cfg.username;
            };
            ssh_master_pub = {
              path = "${user.home}/.ssh/master.pub";
              owner = cfg.username;
            };
          };
          # By default, nix-sops will create the .ssh directory as owned by root.
          system.activationScripts."user-owns-.ssh".text = ''
            chown ${cfg.username} ${user.home}/.ssh
          '';

          users.users.${cfg.username}.hashedPasswordFile =
            config.sops.secrets."${cfg.username}-password".path;
        };
    };
}
