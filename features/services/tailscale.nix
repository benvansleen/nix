_: {
  flake.modules.nixos.tailscale = {
    imports = [ ../../modules/system/tailscale.nix ];

    config.modules.tailscale.enable = true;
  };
}
