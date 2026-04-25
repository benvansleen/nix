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
          home-manager.users.${username}.imports = [
            inputs.self.modules.homeManager.sops
          ];

          users.users.${username}.hashedPasswordFile = config.sops.secrets."${user}-password".path;
        };
    };
}
