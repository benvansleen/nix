{ pkgs, inputs, outputs, ... }:

let
  user = "ben";
in
{
  users.users.${user} = {
    isNormalUser = true;
    description = "ben";
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "networkmanager"
    ];
    packages = [];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ7RtJEcXSq6pCTh9/XdFhJkYhrRwQfUeZcCzdg0o4WP benvansleen@gmail.com"
    ];
  };

  home-manager.users.${user} = import ./home.nix { inherit user pkgs; };
}
