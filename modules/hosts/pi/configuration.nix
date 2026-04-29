{
  flake.modules.nixos.pi-configuration =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      if-using-sops = lib.mkIf (builtins.hasAttr "sops" config);
    in
    {
      config = {
        modules = {
          clonix = {
            enable = true;
            deployments = [
              rec {
                deploymentName = "backup-${config.machine.name}";
                local = {
                  dir = "/";
                  exclude = [
                    "/bin"
                    "/boot"
                    "/dev"
                    "/lib"
                    "/mnt"
                    "/nix"
                    "/proc"
                    "/run"
                    "/sys"
                    "/usr"
                  ];
                };
                targetDir = "${lib.constants.backup-path}/${deploymentName}";
                remote.enable = false;
                should-propagate-file-deletion = true;
                timer = {
                  enable = true;
                  OnCalendar = "hourly";
                  Persistent = true;
                };
              }
            ];
          };
          containers = {
            disable-podman-dns = true;
          };
          maybe.enable = true;
          pihole.enable = false;
          searx = {
            enable = false;
            port = 8888;
          };
          tailscale = {
            authKeyFile = if-using-sops config.sops.secrets.tailscale_authkey.path;
            tailscale-up-extra-args = [
              "--ssh"
              "--accept-risk=lose-ssh"
              "--exit-node=auto:any"
              "--advertise-routes=192.168.1.0/24"
            ];
          };
          unbound = {
            enable = false;
            port = 5335;
            num-threads = 4;
          };
        };

        environment.systemPackages = with pkgs; [
          dig
        ];

        services.openssh.enable = true;
        networking.wireless.enable = false;

        system.stateVersion = "23.11";
      };
    };
}
