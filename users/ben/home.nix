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


  # programs.hyprland = {
  #   enable = true;
  # };

  programs.git = {
    enable = true;
    userName = user;
    userEmail = "benvansleen@gmail.com";
    extraConfig = {
      init.defaultBranch = "master";
    };
  };

  # programs.nix-ld.enable = true;


  home.stateVersion = "24.11";
}
