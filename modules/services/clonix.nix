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
      options.services.clonix = with lib; {
        deployments = mkOption {
          type = with types; listOf anything;
          default = [ ];
          description = "list of deployments to be managed by clonix; see https://github.com/tulilirockz/clonix for options";
        };
      };
      config = {
        services.clonix = {
          inherit (config.services.clonix) deployments;
          enable = true;
        };
      };
    };
}
