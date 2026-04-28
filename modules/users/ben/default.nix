{
  inputs,
  self,
  ...
}:

let
  user = "ben";
  homeDir = "/home/${user}";
in
{
  flake.modules.homeManager.${user} =
    {
      osConfig,
      pkgs,
      lib,
      ...
    }:
    {
      imports = with self.modules.homeManager; [
        ben-cli
        ben-programs
        ben-stylix
        ben-windowManager

        containers
        impermanence
        firefox
        ollamaCopilot
      ];

      config =
        let
          dirs = {
            root = homeDir;
            config = ".config";
            data = ".local/share";
            state = ".local/state";
            cache = ".cache";
          };
        in
        {
          persist.directories = [
            "${dirs.config}/nix"
            "Code"
            "Documents"
            "Downloads"
            "Pictures"
          ]
          ++ lib.optionals osConfig.services.hardware.openrgb.enable [
            "${dirs.config}/OpenRGB"
          ];

          modules = {
            ollama-copilot = {
              num-tokens = 30;
              model = "hf.co/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:Q4_K_XL";
              system = "respond only by completing the code. What you write after <MID> will be directly inserted between <PRE> and <SUF>.";
            };
            windowManager = {
              terminal = pkgs.ghostty;
            };
          };

          home = {
            username = user;
            homeDirectory = dirs.root;
            packages = with pkgs; [
              bandwhich
              nix-output-monitor
              nh
              nixd
            ];

            file.".ssh/config".text = ''
              IdentityFile ${dirs.root}/.ssh/master
              UpdateHostKeys no
            '';
          };

          xdg = {
            enable = true;
            configHome = "${dirs.root}/${dirs.config}";
            dataHome = "${dirs.root}/${dirs.data}";
            stateHome = "${dirs.root}/${dirs.state}";
          };

          programs.git.settings.user = {
            inherit (inputs.secrets.personal-info) email;
            name = user;
          };

          sops = inputs.secrets.${user} "${dirs.root}/.ssh/master" // {
            secrets.github_copilot.path = "${dirs.config}/github-copilot/apps.json";
          };

          home.stateVersion = "24.11";
        };
    };

  flake.modules.nixos.${user} =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = with self.modules.nixos; [
        sops-user
      ];

      home-manager.users.${user}.imports = [
        self.modules.homeManager.${user}
      ];

      modules = {
        k3s.users = [ user ];
        sops-user.username = user;
      };

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
