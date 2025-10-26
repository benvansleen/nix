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
          pkg = pkgs.firefox-wayland;
          config = osConfig;
        };
      };
      ollama-copilot = {
        enable = true;
        num-tokens = 30;
        model = "hf.co/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:Q4_K_XL";
        system = "respond only by completing the code. What you write after <MID> will be directly inserted between <PRE> and <SUF>.";
      };
      window-manager = {
        enable = osConfig.machine.desktop;
        terminal = pkgs.ghostty;
      };
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
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
        settings = {
          user = {
            name = user;
            email = "benvansleen@gmail.com";
          };
          init.defaultBranch = "master";
        };
      };
    };

    sops = secrets "${homeDir.root}/.ssh/master" // {
      secrets.github_copilot.path = "${homeDir.config}/github-copilot/apps.json";
    };

    home.stateVersion = "24.11";
  };
}
