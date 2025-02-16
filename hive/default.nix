{
  inputs,
  lib,
  overlays,
}:

let
  inherit (inputs) nixpkgs;
in
{
  meta =
    let
      nixpkgs-config = system: {
        inherit system overlays;
      };
    in
    {
      specialArgs = {
        inherit lib;
      } // inputs;
      nixpkgs = import nixpkgs (nixpkgs-config "x86_64-linux");
      nodeNixpkgs = {
        pi = import nixpkgs (nixpkgs-config "aarch64-linux");
      };
    };

  defaults = {
    imports = [
      ../modules/system
      ../hosts
      ../users
    ];
  };

  amd = {
    imports = [
      ../hosts/amd
    ];

    deployment = {
      allowLocalDeployment = true;
      targetHost = null;
    };
  };

  pi = {
    imports = [
      ../hosts/pi
    ];
    deployment = {
      buildOnTarget = false;
    };
  };
}
