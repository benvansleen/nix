{
  config,
  pkgs,
  lib,
  nixpkgs,
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
  };

  config = {
    modules.system = {
      display-manager.enable = mkDefault true;
      firefox.enable = mkDefault true;
      fonts.enable = mkDefault false;
      home-manager.enable = mkDefault true;
      sops.enable = mkDefault true;
      stylix.enable = mkDefault true;
    };

    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      settings = {
        accept-flake-config = true;
        auto-optimise-store = true;
        cores = 0;
        connect-timeout = 5;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        fallback = true;
        min-free = 128000000; # 128 MB
        nix-path = [ "nixpkgs=${nixpkgs}" ];
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

        ((vim_configurable.override { }).customize {
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

    networking.hostName = config.machine.name;

    programs = {
      nh.flake = ../.;

      # Allow home.persistence.allowOther
      fuse.userAllowOther = mkIf config.modules.system.impermanence.enable true;
    };

    security = {
      sudo = {
        enable = true;
        execWheelOnly = true;
      };

      # Allows pipewire to get (soft) realtime
      rtkit.enable = true;
    };

    services = {
      dbus.implementation = "broker";
      fstrim.enable = true;
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
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

    users.users.root = {
      hashedPassword = null;
      hashedPasswordFile = mkIf config.modules.system.sops.enable config.sops.secrets.root-password.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINioMpgKUSAxRhCf7rpH7n1OJgpGog2Uxm+jYfCwS4PL benvansleen@gmail.com"
      ];
    };
  };
}
