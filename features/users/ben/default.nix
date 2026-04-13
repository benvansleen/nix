{
  inputs,
  lib,
  ...
}:
let
  user = "ben";
  homeDir = "/home/${user}";
in
{
  flake.modules.homeManager.ben = {

    # home-manager.users.${user}.imports =
    #   with inputs.self.modules.homeManager;
    #   [
    #     ben
    #     impermanence
    #     sops
    #   ]
    #   ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
    #     inputs.centerpiece.hmModules.x86_64-linux.default
    #   ];

    imports = [
      inputs.self.modules.homeManager.ben-ghostty
      inputs.self.modules.homeManager.ben-nvim

      inputs.self.modules.homeManager.impermanence
      inputs.self.modules.homeManager.sops

      (import ../../../users/ben/home.nix {
        inherit inputs;
        inherit user;
        directory = homeDir;
        secrets = inputs.secrets.${user};
      })
    ];
  };

  flake.modules.nixos.ben =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        (inputs.self.lib.sops-user user)
      ];

      home-manager.users.${user}.imports = [
        inputs.self.modules.homeManager.ben
      ];

      programs = {
        hyprland = {
          enable = config.machine.desktop;
          withUWSM = true;
          xwayland.enable = true;
        };
        zsh.enable = true;
      };

      users.users.${user} = {
        isNormalUser = true;
        shell = if config.machine.desktop then pkgs.nushell else pkgs.zsh;
        home = homeDir;

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
