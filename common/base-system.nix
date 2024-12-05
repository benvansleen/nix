{
  pkgs,
  home-manager,
  nix-index-database,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    accept-flake-config = true;
    cores = 0;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
    use-xdg-base-directories = true;
  };
  nix.extraOptions = '''';

  imports = [
    home-manager.nixosModules.home-manager
    nix-index-database.nixosModules.nix-index

    ../users

    ./fonts.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  environment.systemPackages = with pkgs; [
    bat
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

  programs.command-not-found.enable = false;
  programs.bash.interactiveShellInit = ''
    source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
  '';

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

}
