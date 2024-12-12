{
  config,
  pkgs,
  impermanence,
  sops-nix,
  ...
}:

let
  user = "ben";
  home-dir = config.home-manager.users.${user}.home.homeDirectory;
in
{
  sops.secrets.user-password = {
    sopsFile = ../../secrets/user-password.sops;
    format = "binary";
    neededForUsers = true;
  };
  sops.secrets.ssh_master_pem = {
    path = "${home-dir}/.ssh/master";
    owner = user;
  };
  sops.secrets.ssh_master_pub = {
    path = "${home-dir}/.ssh/master.pub";
    owner = user;
  };

  programs.zsh.enable = true;
  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.user-password.path;

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

  home-manager.users.${user} = {
    imports = [
      impermanence.homeManagerModules.impermanence
      sops-nix.homeManagerModules.sops
      (import ./home.nix { inherit user pkgs; })
    ];
  };
}
