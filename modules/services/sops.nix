{ inputs, ... }:
{
  flake-file.inputs = {

    sops-nix.url = "github:Mic92/sops-nix";

    secrets = {
      url = "git+ssh://git@github.com/benvansleen/secrets.git";
      # url = "path:/home/ben/.config/nix/secrets";
    };
  };

  flake.modules.nixos.sops =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      config = lib.mkMerge [
        {
          # The persisted /etc isn't mounted fast enough
          # From https://github.com/profiluefter/nixos-config/blob/09a56c8096c7cbc00b0fbd7f7c75d6451af8f267/sops.nix
          sops = inputs.secrets.system "${
            if (config.environment ? persistence) then config.persist.root else ""
          }/etc/ssh/ssh_host_ed25519_key";

          users.mutableUsers = false;
          users.users.root = {
            hashedPassword = null;
            hashedPasswordFile = config.sops.secrets.root-password.path;
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINioMpgKUSAxRhCf7rpH7n1OJgpGog2Uxm+jYfCwS4PL benvansleen@gmail.com"
            ];
          };
        }

        (lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 {
          sops.package = (pkgs.callPackage "${inputs.sops-nix}" { }).sops-install-secrets.overrideAttrs (_: {
            outputs = [ "out" ];
            dontFixup = true;
            dontStrip = true;
            postInstall = "";
          });
        })
      ];
    };

  flake.modules.homeManager.sops = {
    imports = [
      (inputs.sops-nix.homeManagerModules.default or inputs.sops-nix.homeManagerModules.sops)
    ];
  };
}
