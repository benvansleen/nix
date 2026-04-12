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
  flake-file.inputs.centerpiece = {
    url = "github:friedow/centerpiece";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
      treefmt-nix.follows = "treefmt-nix";
    };
  };

  flake.modules.homeManager.ben = {
    imports = [
      (inputs.nvim.homeManagerModules.default or inputs.nvim.homeManagerModules.nvim)
      (inputs.sops-nix.homeManagerModules.default or inputs.sops-nix.homeManagerModules.sops)
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
    let
      ifUsingSops = lib.mkIf config.modules.sops.enable;
    in
    {
      home-manager.users.${user}.imports = [
        inputs.self.modules.homeManager.ben
        inputs.self.modules.homeManager.impermanence
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        inputs.centerpiece.hmModules.x86_64-linux.default
      ];

      sops.secrets = ifUsingSops {
        ssh_master_pem = {
          path = "${homeDir}/.ssh/master";
          owner = user;
        };
        ssh_master_pub = {
          path = "${homeDir}/.ssh/master.pub";
          owner = user;
        };
      };

      # By default, nix-sops will create the .ssh directory as owned by root.
      system.activationScripts."user-owns-.ssh".text = ifUsingSops ''
        chown ${user} ${homeDir}/.ssh
      '';

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
        hashedPasswordFile = ifUsingSops config.sops.secrets."${user}-password".path;
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
