{ config, lib, ... }:

let
  if-using-sops = lib.mkIf config.modules.sops.enable;
in
lib.importAll ./.
// {
  config = {
    modules = {
      caddy.enable = true;
      containers.enable = true;
      display-manager.enable = false;
      firefox.enable = false;
      fonts.enable = false;
      home-manager.enable = true;
      impermanence.enable = false;
      pihole.enable = true;
      searx = {
        enable = true;
        port = 8888;
      };
      sops.enable = true;
      stylix.enable = false;
      tailscale = {
        enable = true;
        authKeyFile = if-using-sops config.sops.secrets.tailscale_authkey.path;
        tailscale-up-extra-args = [
          "--ssh"
          "--exit-node=us-qas-wg-101.mullvad.ts.net." # Ashburn, VA
          "--exit-node-allow-lan-access" # Necessary for pihole DNS
          "--advertise-routes=192.168.1.0/24"
        ];
      };
    };

    services.openssh.enable = true;
    networking.wireless.enable = false;

    system.stateVersion = "23.11";
  };
}
