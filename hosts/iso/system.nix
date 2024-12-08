{ pkgs, ... }:

{
  nix.settings.max-jobs = 4;
  networking.hostName = "iso";
  environment.systemPackages = with pkgs; [ ];

  isoImage.squashfsCompression = "gzip -Xcompression-level 1";
  system.activationScripts.nixos-config.text = ''
    if [[ ! -e /nixos-config ]]; then
        cp -r ${../../.} /nixos-config
    fi
  '';
}
