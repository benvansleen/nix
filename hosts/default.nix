{
  nixos-facter-modules,
  nixpkgs,
  config,
  pkgs,
  lib,
  secrets,
  ...
}:

let
  inherit (lib)
    mkIf
    mkDefault
    mkOption
    mkEnableOption
    types
    ;
in
{
  options.machine = {
    name = mkOption {
      type = types.str;
      default = "nixos";
      description = "The hostname of the machine";
    };
    allowUnfree = mkEnableOption "Allow unfree nixpkgs";
    powerful = mkEnableOption "Powerful machine configuration";
    desktop = mkEnableOption "Desktop machine configuration; enable gui apps";
  };

  imports = [
    nixos-facter-modules.nixosModules.facter
  ];

  config = {
    facter.report = secrets.hardware."${config.machine.name}-facter.json";

    modules = {
      containers.enable = mkDefault true;
      display-manager.enable = mkDefault true;
      firefox.enable = mkDefault true;
      fonts.enable = mkDefault false;
      home-manager.enable = mkDefault true;
      nixos-cli.enable = mkDefault true;
      sops = {
        enable = mkDefault true;
        system-secrets = secrets.system;
      };
      stylix.enable = mkDefault true;
      zsa.enable = mkDefault true;
    };

    nixpkgs.flake = {
      setNixPath = true;
      setFlakeRegistry = true;
    };
    nix = {
      buildMachines = [
        {
          hostName = "amd";
          sshUser = "remotebuild";
          protocol = "ssh-ng";
          systems = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          speedFactor = 10;
          maxJobs = 32;
          supportedFeatures = [
            "nixos-test"
            "big-parallel"
            "kvm"
          ];
        }
      ];
      channel.enable = false;
      distributedBuilds = true;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      registry.nixpkgs.flake = nixpkgs;
      settings = {
        accept-flake-config = true;
        auto-optimise-store = true;
        builders-use-substitutes = true;
        cores = 0;
        connect-timeout = 5;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        fallback = true;
        min-free = 128000000; # 128 MB
        trusted-users = [ "@wheel" ];
        use-xdg-base-directories = true;
        warn-dirty = false;
      };
    };

    environment = {
      systemPackages = with pkgs; [
        bat
        bottom
        fd
        git
        htop-vim
        procs
        ripgrep

        # To use graphical wayland applications over ssh
        ## 1. Ensure `waypipe` is installed on both client and server
        ## 2. From client: `waypipe ssh <user>@<host> <command>`
        waypipe

        ((vim-full.override { }).customize {
          name = "vim";
          vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
            start = [
              vim-nix
              vim-lastplace
            ];
            opt = [ ];
          };
          vimrcConfig.customRC = ''
            imap jj <C-[>
            nmap ; :
            set nocompatible
            set backspace=indent,eol,start
            syntax on
          '';
        })
      ];

      variables = {
        EDITOR = "vim";
      };
    };

    networking = {
      hostName = config.machine.name;
      firewall = {
        enable = true;
      }
      // lib.optionalAttrs config.modules.tailscale.enable {
        trustedInterfaces = [ "tailscale0" ];
        # close all ports; only accessible via tailnet
        allowedTCPPorts = lib.mkForce [ ];
        allowedUDPPorts = lib.mkForce [ ];
      };
    };

    programs = {
      # Allow home.persistence.allowOther
      fuse.userAllowOther = mkIf config.modules.impermanence.enable true;
    };

    security = {
      doas = {
        enable = lib.constants.privilege-escalation == "doas";
        extraRules = [
          {
            groups = [ "wheel" ];
            keepEnv = true;
            noPass = false;
            persist = true;
          }
        ];
      };
      sudo = {
        enable = lib.constants.privilege-escalation == "sudo";
        execWheelOnly = true;
      };

      # Allows pipewire to get (soft) realtime
      rtkit.enable = true;
    };

    services = {
      dbus.implementation = "broker";
      fstrim.enable = true;
      openssh.settings.PermitRootLogin = "no";
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };

    system.activationScripts = {
      diffGens = ''
        ${lib.getExe pkgs.dix} /run/current-system "$systemConfig"
      '';
    };

    time.timeZone = "America/New_York";
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
    };

    users.mutableUsers = false;
    users.users.root = {
      hashedPassword = null;
      hashedPasswordFile = mkIf config.modules.sops.enable config.sops.secrets.root-password.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINioMpgKUSAxRhCf7rpH7n1OJgpGog2Uxm+jYfCwS4PL benvansleen@gmail.com"
      ];
    };
  };
}
