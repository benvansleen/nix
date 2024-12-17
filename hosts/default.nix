{
  globals,
  config,
  pkgs,
  lib,
  nix-index-database,
  nixpkgs,
  ...
}:

let
  inherit (lib) mkIf mkDefault;
in
{
  imports = [
    nix-index-database.nixosModules.nix-index
  ];

  modules.system = {
    fonts.enable = mkDefault true;
    home-manager.enable = mkDefault true;
    impermanence.persistRoot = mkDefault globals.persistRoot;
    sops.enable = mkDefault true;
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

  boot = {
    initrd.systemd.enable = true;
    binfmt.emulatedSystems = [
      "wasm32-wasi"
      "x86_64-windows"
      "aarch64-linux"
    ];
  };

  programs = {
    command-not-found.enable = false;
    bash.interactiveShellInit = ''
      source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
    '';

    # Allow home.persistence.allowOther
    fuse.userAllowOther = mkIf config.modules.system.impermanence.enable true;
  };

  security = {
    sudo = {
      enable = true;
      execWheelOnly = true;
      # When /etc is not persisted, sudo lectures on first use every boot
      extraConfig = ''
        Defaults lecture=never
      '';
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

  users = {
    mutableUsers = false;
    users.root = {
      hashedPassword = null;
      hashedPasswordFile = config.sops.secrets.root-password.path;
    };
  };
}
