{ user, pkgs, ... }:

{
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    packages = with pkgs; [
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
