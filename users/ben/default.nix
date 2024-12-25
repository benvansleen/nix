{
  config,
  pkgs,
  lib,
  ...
}@inputs:

let
  inherit (lib) mkIf;
  user = "ben";
  home-dir = "/home/${user}";
  if-using-sops = mkIf config.modules.system.sops.enable;
in
lib.mkUser {
  inherit user;
  enable = mkIf config.modules.system.home-manager.enable;
  extraHomeModules = [
    (import ./home.nix (
      inputs
      // {
        inherit user;
        inherit (config) machine;
        directory = home-dir;
      }
    ))
  ];
  extraConfig = {
    sops.secrets = if-using-sops {
      user-password = {
        sopsFile = ../../secrets/user-password.sops;
        format = "binary";
        neededForUsers = true;
      };
      ssh_master_pem = {
        path = "${home-dir}/.ssh/master";
        owner = user;
      };
      ssh_master_pub = {
        path = "${home-dir}/.ssh/master.pub";
        owner = user;
      };
    };

    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };
      zsh.enable = true;
    };
    users.users.${user} = {
      isNormalUser = true;
      shell = pkgs.zsh;
      hashedPasswordFile = if-using-sops config.sops.secrets.user-password.path;
      home = home-dir;

      description = "Ben Van Sleen";
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "network"
        "networkmanager"
      ];

      packages = [ ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7RtJEcXSq6pCTh9/XdFhJkYhrRwQfUeZcCzdg0o4WP benvansleen@gmail.com"
      ];
    };
  };
}
