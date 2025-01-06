{
  user,
  directory,
}:
{
  pkgs,
  systemConfig,
  ...
}:

let
  inherit (systemConfig) machine;
  homeDir = {
    root = directory;
    config = ".config";
    data = ".local/share";
    state = ".local/state";
    cache = ".cache";
  };
in
{
  imports = [
    ./etc
  ];

  config = {
    modules.home = {
      impermanence = {
        inherit homeDir;
        persistedDirectories = [
          "${homeDir.config}/nix"
          "Code"
          "Documents"
          "Downloads"
          "Pictures"
        ];
      };
      cli.enable = true;
      emacs = {
        enable = systemConfig.machine.desktop;
        init-el = ./etc/emacs/init.el;
        framesOnlyMode = true;
        nativeBuild = machine.powerful;
      };
      firefox = {
        enable = systemConfig.machine.desktop;
        browser-pkg = pkgs.floorp;
      };
      window-manager = {
        enable = systemConfig.machine.desktop;
        terminal = pkgs.ghostty;
      };
    };

    nix.gc = {
      automatic = true;
      frequency = "weekly";
      options = "--delete-older-than 30d";
    };

    home = {
      username = user;
      homeDirectory = homeDir.root;
      packages = with pkgs; [
        bandwhich
        bottom
        nix-output-monitor
        nh
        nixd
      ];

      file.".ssh/config".text = "IdentityFile ${homeDir.root}/.ssh/master";
    };

    xdg =
      let
        inherit (homeDir)
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
      bottom.enable = true;
      git = {
        enable = true;
        userName = user;
        userEmail = "benvansleen@gmail.com";
      };
    };

    sops = {
      defaultSopsFile = ./secrets.yaml;
      age.sshKeyPaths = [
        "${homeDir.root}/.ssh/master"
      ];
      secrets.github_copilot = {
        path = "${homeDir.config}/github-copilot/hosts.json";
      };
    };

    home.stateVersion = "24.11";
  };
}
