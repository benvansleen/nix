{
  config,
  lib,
  sops-nix,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.sops;
  impermanence-cfg = config.modules.impermanence;
  inherit (impermanence-cfg) persistRoot;
in
{
  options.modules.sops = {
    enable = mkEnableOption "sops";
  };

  imports = [
    sops-nix.nixosModules.sops
  ];

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets/default.yaml;
      defaultSopsFormat = "yaml";
      gnupg.sshKeyPaths = [ ];
      age.sshKeyPaths =
        let
          hostKeyPath =
            (if impermanence-cfg.enable then persistRoot else "") + "/etc/ssh/ssh_host_ed25519_key";
        in
        [
          # The persisted /etc isn't mounted fast enough
          # From https://github.com/profiluefter/nixos-config/blob/09a56c8096c7cbc00b0fbd7f7c75d6451af8f267/sops.nix
          hostKeyPath
        ];
      secrets = {
        root-password = {
          sopsFile = ../../secrets/root-password.sops;
          format = "binary";
          neededForUsers = true;
        };
        tailscale_authkey = { };
        cloudflare_caddy_api_token = { };
        tailscale_sidecar_authkey = { };
        searx_secretkey = { };
        pihole_webpassword = { };
      };
    };
  };
}
