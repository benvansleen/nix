{ user, pkgs, ... }:

{
  imports = [
    ../../features/cli
    ../../features/window-manager.nix
    ../../features/emacs
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    packages = with pkgs; [
      nix-output-monitor
      nh
      nixd
    ];
  };

  programs.git = {
    enable = true;
    userName = user;
    userEmail = "benvansleen@gmail.com";
    extraConfig = {
      init.defaultBranch = "master";
    };
  };

  home.stateVersion = "24.11";
}
