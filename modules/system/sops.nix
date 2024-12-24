{
  config,
  lib,
  sops-nix,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.system.sops;
  inherit (config.modules.system.impermanence) persistRoot;
in
{
  options.modules.system.sops = {
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
      age.sshKeyPaths = [
        # The persisted /etc isn't mounted fast enough
        # From https://github.com/profiluefter/nixos-config/blob/09a56c8096c7cbc00b0fbd7f7c75d6451af8f267/sops.nix
        "${persistRoot}/etc/ssh/ssh_host_ed25519_key"
        # "/etc/ssh/ssh_host_ed25519_key"
      ];
      secrets.root-password = {
        sopsFile = ../../secrets/root-password.sops;
        format = "binary";
        neededForUsers = true;
      };
    };
  };
}
