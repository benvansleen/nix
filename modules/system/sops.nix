{
  config,
  lib,
  sops-nix,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.sops;
  impermanence-cfg = config.modules.impermanence;
  inherit (impermanence-cfg) persistRoot;
in
{
  options.modules.sops = {
    enable = mkEnableOption "sops";
    system-secrets = mkOption {
      type = types.anything;
      description = "system-level `sops-nix` config; this setting allows secret management to stored separately from main config";
    };
  };

  imports = [
    sops-nix.nixosModules.sops
  ];

  config = mkIf cfg.enable {
    # The persisted /etc isn't mounted fast enough
    # From https://github.com/profiluefter/nixos-config/blob/09a56c8096c7cbc00b0fbd7f7c75d6451af8f267/sops.nix
    sops = cfg.system-secrets "${
      if impermanence-cfg.enable then persistRoot else ""
    }/etc/ssh/ssh_host_ed25519_key";
  };
}
