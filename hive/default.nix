{
  inputs,
  lib,
  overlays,
}:

let
  inherit (inputs) nixpkgs nixpkgs-stable;
in
{
  meta =
    let
      nixpkgs-config = system: {
        inherit system overlays;
      };

      specialArgs =
        system:
        {
          inherit lib;
          pkgs-stable = import nixpkgs-stable (nixpkgs-config system);
          pkgs-unfree = import nixpkgs (
            (nixpkgs-config system)
            // {
              config.allowUnfree = true;
            }
          );
        }
        // inputs;
    in
    {
      nixpkgs = import nixpkgs (nixpkgs-config "x86_64-linux");
      specialArgs = specialArgs "x86_64-linux";

      nodeNixpkgs = {
        pi = import nixpkgs (nixpkgs-config "aarch64-linux");
      };
      nodeSpecialArgs = {
        pi = specialArgs "aarch64-linux";
      };

    };

  defaults = _: {
    imports = [
      ../modules/system
      ../hosts
      ../users
    ];
  };

  amd = _: {
    imports = [
      ../hosts/amd
    ];

    deployment = {
      allowLocalDeployment = true;
      targetHost = null;
    };
  };

  pi = _: {
    imports = [
      ../hosts/pi
    ];
    deployment = {
      targetHost = "pi";
      buildOnTarget = false;
    };
  };
}
