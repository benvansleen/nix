{
  config,
  lib,
  ...
}:

let
  if-using-sops = lib.mkIf config.modules.sops.enable;
in
{
  config = {
    modules = {
      clonix = {
        enable = true;
        deployments = [
          rec {
            deploymentName = "backup-${config.machine.name}";
            local = {
              dir = "/persist";
              exclude = [
                "**/llama/models/"
                "**/.cache/"
                "**/.local/"
              ];
            };
            targetDir = "${lib.constants.backup-path}/${deploymentName}";
            remote = {
              enable = true;
              ipOrHostname = "pi";
              user.name = "root";
            };
            should-propagate-file-deletion = true;
            timer = {
              enable = true;
              OnCalendar = "hourly";
              Persistent = true;
            };
          }
        ];
      };
      impermanence = {
        enable = true;
        persistRoot = "/persist";
      };
      prometheus.client.enable = true;
      tailscale = {
        enable = true;
        authKeyFile = if-using-sops config.sops.secrets.tailscale_authkey.path;
        tailscale-up-extra-args = [
          "--accept-routes"
          "--exit-node=us-chi-wg-301.mullvad.ts.net"
        ];
      };
      searx.enable = false;
    };

    nix = {
      gc.automatic = lib.mkForce false;
      settings = {
        cores = lib.mkForce 12;
        max-jobs = 6;
      };
    };

    boot = {
      binfmt.emulatedSystems = [
        "wasm32-wasi"
        "x86_64-windows"
        "aarch64-linux"
      ];
      initrd.systemd.enable = true;
      loader = {
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
        grub = {
          enable = true;
          useOSProber = true;
          efiSupport = true;
          device = "nodev";
        };
      };
    };

    networking = {
      # nftables.enable = true;
      networkmanager = {
        enable = true;
        # wifi.backend = "iwd";
      };
      # wireless.iwd.enable = true;
    };

    ## Without this, rebuilding os hangs
    systemd = {
      services.NetworkManager-wait-online.enable = false;
      network.wait-online.enable = false;
    };

    services = {
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      irqbalance.enable = false;
      thermald.enable = false;
    };

    # Experimental
    ## Currently get `mkcomposefs: command not found` error
    # system.etc.overlay.enable = true;

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
