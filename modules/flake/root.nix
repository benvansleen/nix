{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-file.flakeModules.default
    inputs.flake-parts.flakeModules.modules
  ];

  flake-file.outputs = lib.mkDefault "inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } ./flake-file.nix";
  systems = lib.mkDefault (import inputs.systems);
}
