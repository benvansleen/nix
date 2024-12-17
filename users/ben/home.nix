{
  user,
  pkgs,
  ...
}@inputs:

let
  home-dir = {
    root = "/home/${user}";
    config = ".config";
    data = ".local/share";
    state = ".local/state";
  };
in
rec {
  imports = [
    (import ./impermanence.nix (inputs // { inherit home-dir; }))
  ];

  modules.home = {
    cli.enable = true;
    emacs.enable = true;
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
      "${home-dir.root}/.ssh/master"
    ];
    secrets.github_copilot = {
      path = "${xdg.configHome}/github-copilot/hosts.json";
    };
  };

  home.stateVersion = "24.11";
}
