{ user, pkgs, ... }:

{
  imports = [
    ../../features/cli
    ../../features/window-manager.nix
    ../../features/emacs
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    packages = with pkgs; [
      bandwhich
	  bottom
      nix-output-monitor
      nh
      nixd
    ];

	persistence."/nix/persist/home/${user}" = {
	  allowOther = true;
	  directories = [
		".config/nix"
		".ssh"
		"Documents"
		"Downloads"
		"Code"
	  ];
	};

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

  home.stateVersion = "24.11";
}
