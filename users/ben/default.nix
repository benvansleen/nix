{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:

let
  inherit (lib) mkIf;
  user = baseNameOf ./.;
  home-dir = "/home/${user}";
  if-using-sops = mkIf config.modules.sops.enable;
in
lib.mkUser {
  inherit user;
  enable = mkIf config.modules.home-manager.enable;
  extraHomeModules = [
    (import ./home.nix {
      inherit user;
      directory = home-dir;
      secrets = secrets.${user};
    })
  ];
  extraConfig = {
    sops.secrets = if-using-sops {
      ssh_master_pem = {
        path = "${home-dir}/.ssh/master";
        owner = user;
      };
      ssh_master_pub = {
        path = "${home-dir}/.ssh/master.pub";
        owner = user;
      };
    };
    # By default, nix-sops will create the .ssh directory as owned by root
    system.activationScripts."user-owns-.ssh".text = if-using-sops ''
      chown ${user} ${home-dir}/.ssh
    '';

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
      shell = pkgs.nushell;
      hashedPasswordFile = if-using-sops config.sops.secrets."${user}-password".path;
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
