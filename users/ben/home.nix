{
  globals,
  user,
  pkgs,
  ...
}:

let
  home-dir = "home/${user}";
  config-dir-name = ".config";
  data-dir-name = ".local/share";
  state-dir-name = ".local/state";
in
rec {
  imports = [
    ../../features/cli
    (import ../../features/window-manager {
      inherit pkgs;
    })
    ../../features/emacs
  ];

  nix.gc = {
    automatic = true;
    frequency = "weekly";
    options = "--delete-older-than 30d";
  };

  home = {
    username = user;
    homeDirectory = "/${home-dir}";
    packages = with pkgs; [
      bandwhich
      bottom
      nix-output-monitor
      nh
      nixd
    ];

    persistence."${globals.persistRoot}/${home-dir}" = {
      allowOther = true;
      directories = [
        {
          directory = "Code";
          method = "symlink";
        }
        {
          directory = "Documents";
          method = "symlink";
        }
        {
          directory = "Downloads";
          method = "symlink";
        }
        {
          directory = "Pictures";
          method = "symlink";
        }
        "${config-dir-name}/nix"
        {
          directory = "${data-dir-name}/atuin";
          method = "symlink";
        }
      ];
      files = [
        "${data-dir-name}/zsh/history"
      ];
    };

  };

  xdg = {
    enable = true;
    configHome = "${home.homeDirectory}/${config-dir-name}";
    dataHome = "${home.homeDirectory}/${data-dir-name}";
    stateHome = "${home.homeDirectory}/${state-dir-name}";
  };

  programs.git = {
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

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [
      "${home.homeDirectory}/.ssh/master"
    ];
    secrets.github_copilot = {
      path = "${xdg.configHome}/github-copilot/hosts.json";
    };
  };

  home.stateVersion = "24.11";
}
