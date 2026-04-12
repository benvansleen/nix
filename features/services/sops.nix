{ inputs, ... }:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.sops = {
    imports = [ ../../modules/system/sops.nix ];

    config.modules.sops = {
      enable = true;
      system-secrets = inputs.secrets.system;
    };
  };
}
