{ inputs, ... }:

{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      pre-commit.inputs.flake-compat.follows = "flake-compat";
    };
  };

  flake.modules.nixos.secureboot =
    { config, lib, ... }:
    {
      imports = [ inputs.lanzaboote.nixosModules.default ];

      boot = {
        bootspec.enable = true;
        loader = {
          ## replaced by lanzaboote
          systemd-boot.enable = lib.mkForce false;
          grub.enable = lib.mkForce false;

          efi.canTouchEfiVariables = true;
        };
        lanzaboote = {
          enable = true;
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
          pkiBundle = "/var/lib/sbctl";
        };
      };

      persist.directories = [ config.boot.lanzaboote.pkiBundle ];
    };
}
