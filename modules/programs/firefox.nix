{
  flake.modules.nixos.firefox =
    { pkgs, ... }:
    let
      lock-false = {
        Value = false;
        Status = "locked";
      };
      lock-empty = {
        Value = "";
        Status = "locked";
      };
    in
    {
      config = {
        # To enable screensharing in Firefox
        xdg.portal = {
          enable = true;
          config.common.default = "*";
          extraPortals = with pkgs; [
            xdg-desktop-portal-wlr
            xdg-desktop-portal-gtk
          ];
        };

        programs.firefox = {
          enable = true;
          package = pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { };
          policies = {
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
            DontCheckDefaultBrowser = true;
            DisablePocket = true;
            SearchBar = "unified";

            Preferences = {
              "extensions.pocket.enabled" = lock-false;
              "browser.topsites.contile.enabled" = lock-false;
              "browser.newtabpage.pinned" = lock-empty;
              "browser.newtabpage.activity-stream.showSponsored" = lock-false;
              "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
              "browser.ml.chat.enabled" = lock-false;

              # Disable Alt key opening the menu
              "ui.key.menuAccessKey" = 17; # 18 is ALT
              "ui.key.menuAccessKeyFocuses" = false;
            };

            ExtensionSettings = {
              "uBlock0@raymondhill.net" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                installation_mode = "force_installed";
              };
              "jid1-MnnxcxisBPnSXQ@jetpack" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacybadger/latest.xpi";
                installation_mode = "force_installed";
              };
            };
          };
        };
      };
    };

  flake.modules.homeManager.firefox =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.modules.firefox = with lib; {
        browser-pkg = mkOption {
          type = types.package;
          default = pkgs.firefox;
          description = "the package to use as the default browser";
        };
      };

      config =
        let
          cfg = config.modules.firefox;
        in
        {
          persist.directories = with config.xdg; [
            ".mozilla"
            "${cacheHome}/mozilla"

            ".floorp"
            "${cacheHome}/floorp"
          ];

          xdg.desktopEntries = {
            browser = {
              name = "browser";
              exec = lib.getExe cfg.browser-pkg;
              terminal = false;
            };
          };

          stylix.targets.firefox.profileNames = [ "default" ];
          programs.firefox = {
            enable = true;
            package = cfg.browser-pkg;
            ## TODO: migrate to "${config.xdg.configHome}/mozilla/firefox"
            configPath = ".mozilla/firefox";
            profiles = {
              default = {
                id = 0;
                name = "default";
                isDefault = true;
                settings = {
                  "browser.search.defaultenginename" = "DuckDuckGo";
                  "browser.search.order.1" = "DuckDuckGo";

                  "signon.rememberSignons" = false;
                  "widget.use-xdg-desktop-portal.file-picker" = 1;
                  "browser.aboutConfig.showWarning" = false;
                  "browser.compactmode.show" = true;
                  "browser.cache.disk.enable" = false;

                  "mousewheel.default.delta_multiplier_x" = 100;
                  "mousewheel.default.delta_multiplier_y" = 100;
                  "mousewheel.default.delta_multiplier_z" = 100;

                  "sidebar.verticalTabs" = true;
                  "sidebar.expandOnHover" = true;
                  "sidebar.expand-on-hover.duration-ms" = 100;
                };
                search = {
                  force = true;
                  default = "SearxNG";
                  order = [
                    "ddg"
                    "google"
                  ];
                  engines = {
                    "SearxNG" = {
                      urls = [
                        {
                          template = "https://searx.vansleen.dev/search";
                          params = [
                            {
                              name = "q";
                              value = "{searchTerms}";
                            }
                          ];
                        }
                      ];
                    };
                  };
                };
              };
            };
            policies = {
              DontCheckDefaultBrowser = true;
              DisableTelemetry = true;
              DisableFirefoxStudies = true;
              DisablePocket = true;
              DisableFirefoxScreenshots = true;

              DisplayBookmarksToolbar = "never";
              DisplayMenuBar = "never";

              OverrideFirstRunPage = "";
              PictureInPicture.Enabled = false;

              HardwareAcceleration = true;
              TranslateEnabled = true;

              Homepage.StartPage = "previous-session";

              UserMessaging = {
                UrlbarInterventions = false;
                SkipOnboarding = true;
              };

              FirefoxSuggest = {
                WebSuggestions = false;
                SponsoredSuggestions = false;
                ImproveSuggest = false;
              };

              EnableTrackingProtection = {
                Value = true;
                Cryptomining = true;
                Fingerprinting = true;
              };

              FirefoxHome = {
                Search = true;
                TopSites = false;
                SponsoredTopSites = false;
                Highlights = false;
                Pocket = false;
                SponsoredPocket = false;
                Snippets = false;
              };
            };
          };
        };
    };
}
