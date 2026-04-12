{
  inputs,
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
    inputs.self.modules.homeManager.cli
    inputs.self.modules.homeManager.emacs
    inputs.self.modules.homeManager.firefox
    inputs.self.modules.homeManager.stylix
    inputs.self.modules.homeManager.ollamaCopilot
    inputs.self.modules.homeManager.windowManager
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
      emacs = {
        init-el = ./etc/emacs/init.el;
        framesOnlyMode = true;
      };
      firefox = {
        browser-pkg = lib.optimizeForThisHostIfPowerful {
          pkg = pkgs.firefox;
          config = osConfig;
        };
      };
      ollama-copilot = {
        num-tokens = 30;
        model = "hf.co/unsloth/Qwen3-30B-A3B-Instruct-2507-GGUF:Q4_K_XL";
        system = "respond only by completing the code. What you write after <MID> will be directly inserted between <PRE> and <SUF>.";
      };
      window-manager = {
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

      file.".ssh/config".text = ''
        IdentityFile ${homeDir.root}/.ssh/master
        UpdateHostKeys no
      '';
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
