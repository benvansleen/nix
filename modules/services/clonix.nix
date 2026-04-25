{ inputs, ... }:
{
  flake-file.inputs.clonix = {
    url = "github:benvansleen/clonix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.clonix =
    { config, lib, ... }:
    {
      imports = [ inputs.clonix.nixosModules.clonix ];
      options.modules.clonix = with lib; {
        enable = mkEnableOption "clonix";
        deployments = mkOption {
          type = with types; listOf anything;
          default = [ ];
          description = "list of deployments to be managed by clonix; see https://github.com/tulilirockz/clonix for options";
        };
      };
      config =
        let
          cfg = config.modules.clonix;
        in
        {
          modules.clonix = lib.mkIf cfg.enable {
            inherit (cfg) deployments;
            enable = true;
          };
        };
    };
}
