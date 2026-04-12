{ lib, ... }:
{
  flake.modules.nixos.prometheusServer = {
    imports = [ ../../modules/system/prometheus/server.nix ];

    config.modules.prometheus.server.enable = lib.mkDefault true;
  };
}
