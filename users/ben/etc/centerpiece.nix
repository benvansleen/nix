{ lib, config, ... }:

let
  inherit (lib)
    mkIf
    mkOption
    types
    optionalAttrs
    ;
  cfg = config.modules.window-manager.centerpiece;
  available = builtins.hasAttr "centerpiece" config.programs;
in
{
  options.modules.window-manager.centerpiece = {
    enable = mkOption {
      default = available;
      type = types.bool;
      description = "enable centerpiece omnisearch";
    };
  };
  config = mkIf cfg.enable {
    programs = optionalAttrs available {
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
