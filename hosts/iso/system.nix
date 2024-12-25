{
  pkgs,
  lib,
  ...
}:

{
  config = {
    modules.system = {
      display-manager.enable = false;
      impermanence.enable = false;
      sops.enable = false;
    };
    environment.systemPackages = with pkgs; [ ];

    users.users.root = {
      password = "nixos";
      initialPassword = lib.mkForce null;
      hashedPassword = lib.mkForce null;
      initialHashedPassword = lib.mkForce null;
      hashedPasswordFile = lib.mkForce null;
    };
    users.users.ben = {
      password = "nixos";
      initialPassword = lib.mkForce null;
      hashedPassword = lib.mkForce null;
      initialHashedPassword = lib.mkForce null;
      hashedPasswordFile = lib.mkForce null;
    };

    isoImage.squashfsCompression = "zstd -Xcompression-level 2";
    system.activationScripts.nixos-config.text = ''
      if [[ ! -e /nixos-config ]]; then
        cp -r ${../../.} /nixos-config
      fi
    '';
  };
}
