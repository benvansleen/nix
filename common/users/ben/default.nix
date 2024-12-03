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
  };

  home-manager.users.${user} = import ./home.nix { inherit user pkgs; };
}
