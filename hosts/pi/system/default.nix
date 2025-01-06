{
  config,
  pkgs,
  lib,
  ...
}:

let
  if-using-sops = lib.mkIf config.modules.system.sops.enable;
in
lib.importAll ./.
// {
  config = {
    modules.system = {
      containers.enable = true;
      display-manager.enable = false;
      firefox.enable = false;
      fonts.enable = false;
      home-manager.enable = true;
      impermanence.enable = false;
      pi-hole.enable = true;
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
          "--accept-dns=false"
        ];
      };
    };

    services.openssh.enable = true;
    networking.wireless.enable = false;

    systemd.services.tailscale-serve-searx = {
      description = "Serve searx over tailscale";
      after = [
        "tailscale-autoconnect.service"
      ];
      wants = [
        "tailscale-autoconnect.service"
      ];
      serviceConfig.Type = "exec";
      script = with pkgs; ''
        ${lib.getExe tailscale} serve ${toString config.modules.system.searx.port}
      '';
    };

    system.stateVersion = "23.11";
  };
}
