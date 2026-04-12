{ lib, ... }:
{
  flake.modules.nixos.firefox = {
    imports = [ ../../modules/system/firefox.nix ];

    config.modules.firefox.enable = lib.mkDefault true;
  };

  flake.modules.homeManager.firefox = {
    imports = [ ../../modules/home/firefox.nix ];

    config.modules.firefox.enable = lib.mkDefault true;
  };
}
