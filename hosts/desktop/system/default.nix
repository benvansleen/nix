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
        enable = false; # TODO: temporarily disable while restoring data post-repartition
        deployments = [
          rec {
            deploymentName = "backup-${config.machine.name}";
            local = {
              dir = "/persist";
              exclude = [
                "/tmp"
                "**/llama/models/"
                "**/.cache/"
                "**/.local/"
                "**/Code/**/target/"
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
      secureboot.enable = true;
      tailscale = {
        enable = true;
        authKeyFile = if-using-sops config.sops.secrets.tailscale_authkey.path;
        tailscale-up-extra-args = [
          "--ssh"
          "--accept-routes"
          "--exit-node=auto:any"
        ];
      };
      searx.enable = false;
    };

    nix = {
      gc.automatic = lib.mkForce false;
      settings = {
        cores = lib.mkForce 6;
        max-jobs = "auto";
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

    ## TODO: move to `modules.remotebuilder.enable = true`
    nix.settings.trusted-users = [ "remotebuild" ];
    users.groups.remotebuild = { };
    users.users.remotebuild = {
      isSystemUser = true;
      group = "remotebuild";
      useDefaultShell = true;
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
    system.stateVersion = "25.11"; # Did you read the comment?
  };
}
