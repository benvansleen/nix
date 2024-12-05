{
  pkgs,
  ...
}:

let
  user = "ben";
in
{
  programs.zsh.enable = true;
  users.users.${user} = {
    shell = pkgs.zsh;
    isNormalUser = true;
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

  home-manager.users.${user} = import ./home.nix { inherit user pkgs; };
}
