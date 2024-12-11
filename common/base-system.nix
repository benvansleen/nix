{
  config,
  pkgs,
  home-manager,
  sops-nix,
  nix-index-database,
  nixpkgs,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.settings = {
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
  };
  nix.extraOptions = '''';

  imports = [
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    {
      sops = {
        defaultSopsFile = ../secrets/default.env;
        defaultSopsFormat = "dotenv";
        gnupg.sshKeyPaths = [ ];
        age.sshKeyPaths = [
          # The persisted /etc isn't mounted fast enough
          # From https://github.com/profiluefter/nixos-config/blob/09a56c8096c7cbc00b0fbd7f7c75d6451af8f267/sops.nix
          "/nix/persist/etc/ssh/ssh_host_ed25519_key"
        ];
        secrets.root-password = {
          sopsFile = ../secrets/root-password.sops;
          format = "binary";
          neededForUsers = true;
        };
      };
    }
    nix-index-database.nixosModules.nix-index

    ../users
    ./fonts.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
  # Allow home.persistence.allowOther
  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
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
  environment.variables = {
    EDITOR = "vim";
  };

  boot.initrd.systemd.enable = true;
  boot.binfmt.emulatedSystems = [
    "wasm32-wasi"
    "x86_64-windows"
    "aarch64-linux"
  ];

  networking.nftables.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  programs.command-not-found.enable = false;
  programs.bash.interactiveShellInit = ''
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
  '';

  security.sudo = {
    enable = true;
    execWheelOnly = true;
  };

  services.dbus.implementation = "broker";
  services.fstrim.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  # Allows pipewire to get (soft) realtime
  security.rtkit.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
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

  users.mutableUsers = false;
  users.users.root.hashedPasswordFile = config.sops.secrets.root-password.path;
  users.users.root.hashedPassword = null;

}
