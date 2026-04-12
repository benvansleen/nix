{ lib, ... }:
{
  flake.modules.nixos.grafana = {
    imports = [ ../../modules/system/grafana.nix ];

    config.modules.grafana.enable = lib.mkDefault true;
  };
}
