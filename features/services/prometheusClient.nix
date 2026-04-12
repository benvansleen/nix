{ lib, ... }:
{
  flake.modules.nixos.prometheusClient = {
    imports = [ ../../modules/system/prometheus/client.nix ];

    config.modules.prometheus.client.enable = lib.mkDefault true;
  };
}
