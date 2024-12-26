{
  user,
  machine,
  directory,
  pkgs,
  ...
}@inputs:

let
  home-dir = {
    root = directory;
    config = ".config";
    data = ".local/share";
    state = ".local/state";
  };
in
{
  imports = [
    (import ./impermanence.nix (inputs // { inherit home-dir; }))
  ];

  config = {
    modules.home = {
      cli.enable = true;
      emacs = {
        enable = true;
        framesOnlyMode = true;
        nativeBuild = machine.powerful;
      };
      firefox.enable = true;
      window-manager.enable = true;
    };

    nix.gc = {
      automatic = true;
      frequency = "weekly";
      options = "--delete-older-than 30d";
    };

    home = {
      username = user;
      homeDirectory = home-dir.root;
      packages = with pkgs; [
        bandwhich
        bottom
        nix-output-monitor
        nh
        nixd
      ];

      file.".ssh/config".text = "IdentityFile ${home-dir.root}/.ssh/master";
    };

    xdg =
      let
        inherit (home-dir)
          root
          config
          data
          state
          ;
      in
      {
        enable = true;
        configHome = "${root}/${config}";
        dataHome = "${root}/${data}";
        stateHome = "${root}/${state}";
      };

    programs = {
      bottom = {
        enable = true;
        settings = {
          styles.theme = "gruvbox";
          tree = true;
          enable_gpu = true;
          processes.columns = [
            "PID"
            "Name"
            "Mem%"
            "CPU%"
            "GPU%"
            "User"
            "State"
            "R/s"
            "W/s"
            "T.Read"
            "T.Write"
          ];
        };
      };
      git = {
        enable = true;
        userName = user;
        userEmail = "benvansleen@gmail.com";
        extraConfig = {
          init.defaultBranch = "master";
        };
        difftastic = {
          enable = true;
          color = "auto";
          display = "side-by-side";
          background = "dark";
        };
      };
    };

    stylix = {
      enable = true;
      image = ../../modules/home/window-manager/pensacola-beach-dimmed.png;
      autoEnable = true;
      targets.emacs.enable = true;
      fonts.sizes = {
        applications = 12;
        desktop = 12;
        popups = 12;
        terminal = 12;
      };
    };

    sops = {
      defaultSopsFile = ./secrets.yaml;
      age.sshKeyPaths = [
        "${home-dir.root}/.ssh/master"
      ];
      secrets.github_copilot = {
        path = "${home-dir.config}/github-copilot/hosts.json";
      };
    };

    home.stateVersion = "24.11";
  };
}
