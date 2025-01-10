{
  config,
  lib,
  clonix,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.clonix;
in
{
  options.modules.clonix = {
    enable = mkEnableOption "clonix `rsync` service";
    deployments = mkOption {
      type = with types; listOf anything;
      default = [ ];
      description = "list of deployments to be managed by clonix; see https://github.com/tulilirockz/clonix for options";
    };
  };

  imports = [
    clonix.nixosModules.clonix
  ];

  config = mkIf cfg.enable {
    services.clonix = {
      inherit (cfg) enable deployments;
    };
  };
}
