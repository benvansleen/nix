{
  config,
  pkgs,
  impermanence,
  ...
}:

let
  user = "ben";
in
{
  sops.secrets.user-password = {
    sopsFile = ../../secrets/user-password.sops;
    format = "binary";
    neededForUsers = true;
  };

  programs.zsh.enable = true;
  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.user-password.path;

    description = "ben";
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
	  (import ./home.nix { inherit user pkgs; })
	];
  };
}
