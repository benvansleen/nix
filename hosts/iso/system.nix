{ pkgs, ... }:

{
  nix.settings.max-jobs = 4;
  environment.systemPackages = with pkgs; [ ];

  isoImage.squashfsCompression = "zstd -Xcompression-level 2";
  system.activationScripts.nixos-config.text = ''
    if [[ ! -e /nixos-config ]]; then
        cp -r ${../../.} /nixos-config
    fi
  '';
}
