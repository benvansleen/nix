{ pkgs, ... }:

{
  nix.settings.max-jobs = 4;
  networking.hostName = "iso";
  environment.systemPackages = with pkgs; [ ];
}
