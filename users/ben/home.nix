{
  user,
  systemConfig,
  directory,
}:
{
  pkgs,
  ...
}:

let
  inherit (systemConfig) machine;
  home-dir = {
    root = directory;
    config = ".config";
    data = ".local/share";
    state = ".local/state";
    cache = ".cache";
  };
in
{
  imports = [
    (import ./impermanence.nix { inherit home-dir systemConfig; })
    ./stylix.nix
    ./etc
  ];

  config = {
    modules.home = {
      cli.enable = true;
      emacs = {
        enable = true;
        init-el = ./etc/emacs/init.el;
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
        "${home-dir.root}/.ssh/master"
      ];
      secrets.github_copilot = {
        path = "${home-dir.config}/github-copilot/hosts.json";
      };
    };

    home.stateVersion = "24.11";
  };
}
