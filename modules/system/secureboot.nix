{
  lanzaboote,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkForce
    mkOption
    mkEnableOption
    types
    ;
  cfg = config.modules.secureboot;
in
{
  options.modules.secureboot = {
    enable = mkEnableOption "secure boot via lanzaboote";
    pkiBundle = mkOption {
      type = types.str;
      default = "/var/lib/sbctl";
      example = "/var/lib/sbctl";
      description = "where sbctl keys are generated";
    };
  };

  imports = [
    lanzaboote.nixosModules.lanzaboote
  ];

  config = mkIf cfg.enable {
    modules.impermanence.persistedDirectories = [
      cfg.pkiBundle
    ];

    boot = {
      bootspec.enable = true;
      loader = {
        ## replaced by lanzaboote
        systemd-boot.enable = mkForce false;
        grub.enable = mkForce false;
      };
      lanzaboote = {
        enable = true;
        inherit (cfg) pkiBundle;
        autoGenerateKeys.enable = true;
        ## 1. Boot into nixos (requires disabling secure boot)
        ## 2. Ensure `sudo nix run nixpkgs#sbctl verify` shows boot images are signed (excl. kernels)
        ## 3. Clear all existing boot keys in BIOS
        ## 4. `sudo nix run nixpkgs#sbctl enroll-keys -- --microsoft`
        ## 5. May need to re-enroll luks decryption key in TPM
        autoEnrollKeys = {
          enable = false;
          autoReboot = false;
        };
      };
    };
  };
}
