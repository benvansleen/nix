{ inputs, ... }:

{
  flake.lib.sops-user =
    username:
    { config, ... }:
    {
      imports = [ inputs.self.modules.nixos.sops ];

      config =
        let
          user = config.users.users.${username};
        in
        {
          sops.secrets = {
            ssh_master_pem = {
              path = "${user.home}/.ssh/master";
              owner = username;
            };
            ssh_master_pub = {
              path = "${user.home}/.ssh/master.pub";
              owner = username;
            };
          };

          users.users.${username}.hashedPasswordFile = config.sops.secrets."${user}-password".path;

          # By default, nix-sops will create the .ssh directory as owned by root.
          system.activationScripts."user-owns-.ssh".text = ''
            chown ${username} ${user.home}/.ssh
          '';
        };
    };
}
