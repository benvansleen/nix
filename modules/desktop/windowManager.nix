{ inputs, self, ... }:
{
  flake-file.inputs.hyprbar = {
    url = "github:benvansleen/hyprbar";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      pre-commit-hooks.follows = "pre-commit-hooks";
      systems.follows = "systems";
    };
  };

  flake.modules.homeManager.windowManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        (inputs.hyprbar.homeManagerModules.default or inputs.hyprbar.homeManagerModules.hyprbar)
        self.modules.homeManager.gnome-xterm-compat
      ];

      options.modules.windowManager = with lib; {
        terminal = mkOption {
          type = types.package;
          description = "terminal emulator to use";
          default = pkgs.alacritty;
        };
      };

      config =
        let
          cfg = config.modules.windowManager;
          startSystemdService = service: "systemctl --user start --now ${service}.service";
        in
        {
          modules.gnome-xterm-compat.terminal = cfg.terminal;

          home.pointerCursor = {
            gtk.enable = true;
            x11.enable = true;
            package = pkgs.phinger-cursors;
            name = "phinger-cursors-light";
            size = 16;
          };

          home.packages = with pkgs; [
            wl-clipboard
            cliphist
          ];

          programs = {
            hyprlock = {
              enable = true;
              settings = {
                general = {
                  hide_cursor = true;
                  grace = 3;
                  ignore_empty_input = true;
                };

                background = {
                  monitor = "";
                  blur_passes = 3;
                };

                input-field = {
                  monitor = "";
                  shadow_passes = 3;
                  outline_thickness = 2;
                  hide_input = false;
                  rounding = -1;
                };
              };
            };
          };

          hyprbar.enable = true;

          wayland.windowManager.hyprland = {
            enable = true;
            package = pkgs.hyprland;
            portalPackage = pkgs.xdg-desktop-portal-hyprland;
            systemd.enable = false; # Conflicts with UWSM
            plugins = with pkgs.hyprlandPlugins; [
            ];
            settings = {
              exec = lib.map startSystemdService (
                [
                  "hypridle"
                  "hyprpaper" # Enabled by UWSM + stylix
                  "gammastep"
                ]
                ++ lib.optionals config.hyprbar.enable [ "hyprbar" ]
              );

            };
          };

          services = {
            hyprpaper.settings = {
              splash = false;
            };
            hypridle = {
              enable = true;
              settings = {
                general = {
                  lock_cmd = "pidof hyprlock || ${lib.getExe pkgs.hyprlock}";
                  before_sleep_cmd = "loginctl lock-session";
                  after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
                  ignore_dbus_inhibit = false;
                  ignore_systemd_inhibit = false;
                };

                listener = [
                  {
                    timeout = 5 * 60; # 5 minutes
                    on-timeout = "loginctl lock-session";
                  }
                  {
                    timeout = 10 * 60; # 10 minutes
                    on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
                  }
                  {
                    timeout = 30 * 60; # 30 minutes
                    on-timeout = "systemctl suspend";
                  }
                ];
              };
            };

            gammastep = {
              enable = true;
              provider = "manual";
              latitude = 38.8816;
              longitude = -77.0910;
              settings = {
                general = {
                  temp-day = lib.mkForce 6000;
                  temp-night = lib.mkForce 3000;
                  fade = 1;
                  gamma = 0.8;
                  adjustment-method = "wayland";
                };
              };
            };
          };
        };
    };
}
