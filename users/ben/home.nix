{
  user,
  directory,
  secrets,
}:
{
  pkgs,
  lib,
  osConfig,
  ...
}:

let
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
    modules = {
      impermanence = {
        inherit homeDir;
        persistedDirectories = [
          "${homeDir.config}/nix"
          "Code"
          "Documents"
          "Downloads"
          "Pictures"
        ]
        ++ lib.optionals osConfig.services.hardware.openrgb.enable [
          "${homeDir.config}/OpenRGB"
        ];
      };
      cli.enable = true;
      emacs = {
        enable = osConfig.machine.desktop;
        init-el = ./etc/emacs/init.el;
        framesOnlyMode = true;
      };
      firefox = {
        enable = osConfig.machine.desktop;
        browser-pkg = lib.optimizeForThisHostIfPowerful {
          pkg = pkgs.firefox-beta;
          config = osConfig;
        };
      };
      ollama-copilot = {
        enable = true;
        num-tokens = 30;
      };
      window-manager = {
        enable = osConfig.machine.desktop;
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

    sops = secrets "${homeDir.root}/.ssh/master" // {
      secrets.github_copilot.path = "${homeDir.config}/github-copilot/apps.json";
    };

    home.stateVersion = "24.11";
  };
}
