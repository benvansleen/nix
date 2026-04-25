{ inputs, moduleWithSystem, ... }:

{
  flake-file.inputs.centerpiece = {
    url = "github:friedow/centerpiece";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
      treefmt-nix.follows = "treefmt-nix";
    };
  };

  flake.modules.homeManager.centerpiece = moduleWithSystem (
    { system, ... }:
    { lib, ... }:
    let
      available = builtins.hasAttr system inputs.centerpiece.hmModules;
    in
    {
      imports = [
        inputs.centerpiece.hmModules.x86_64-linux.default
      ];

      config = lib.mkIf available {
        programs = {
          centerpiece = {
            enable = true;
            config = {
              color = {
                background = "#202020";
                text = "#ddc7a1";
              };
              plugin = {
                applications.enable = true;
                brave_bookmarks.enable = false;
                brave_history.enable = false;
                brave_progressive_web_apps.enable = false;
                clock.enable = true;
                firefox_bookmarks.enable = false;
                firefox_history.enable = true;
                git_repositories = {
                  enable = true;
                  commands = [
                    [
                      "xterm"
                      "-e"
                      "nvim"
                      "$GIT_DIRECTORY"
                    ]
                  ];
                };
                gitmoji.enable = false;
                resource_monitor_battery.enable = true;
                resource_monitor_cpu.enable = true;
                resource_monitor_disks.enable = true;
                resource_monitor_memory.enable = true;
                sway_windows.enable = false;
                system.enable = true;
                wifi.enable = true;
              };
            };
          };
        };
      };
    }
  );
}
