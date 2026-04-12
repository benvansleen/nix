{ lib, ... }:
{
  flake-file.inputs.clonix = {
    url = "github:benvansleen/clonix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.clonix = {
    imports = [ ../../modules/system/clonix.nix ];

    config.modules.clonix.enable = lib.mkDefault true;
  };
}
