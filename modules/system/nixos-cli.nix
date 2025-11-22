{
  nixos-cli,
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.nixos-cli;
in
{
  imports = [ nixos-cli.nixosModules.nixos-cli ];

  options.modules.nixos-cli = {
    enable = mkEnableOption "nixos-cli";
  };

  config = mkIf cfg.enable {
    services.nixos-cli = {
      enable = true;
      prebuildOptionCache = false;
      useActivationInterface = true;
      config = {
        general = {
          auto_rollback = true;
          color = true;
          root_command = lib.constants.privilege-escalation;
          use_nvd = true;
        };
        apply = {
          ignore_dirty_tree = true;
          use_git_commit_msg = true;
          use_nom = true;
        };
      };
    };
  };
}
