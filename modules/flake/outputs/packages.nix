{ withSystem, inputs, ... }:

{
  flake-file.inputs.pkgs-by-name.url = "github:drupol/pkgs-by-name-for-flake-parts";

  imports = [
    inputs.pkgs-by-name.flakeModule
  ];

  perSystem.pkgsDirectory = ../../../packages;

  flake.overlays.local =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:
      {
        local = config.packages;
      }
    );

}
