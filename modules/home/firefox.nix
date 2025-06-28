{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.firefox;
in
{
  options.modules.firefox = {
    enable = mkEnableOption "firefox";
    browser-pkg = mkOption {
      type = types.enum (
        with pkgs;
        [
          firefox
          floorp
        ]
      );
      default = pkgs.firefox;
      description = "the package to use as the default browser";
    };
  };

  config = mkIf cfg.enable {
    modules.impermanence.persistedDirectories = [
      ".mozilla"
      "@cache@/mozilla"

      ".floorp"
      "@cache@/floorp"
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
          };
          search = {
            force = true;
            default = "DuckDuckGo";
            order = [
              "DuckDuckGo"
              "Google"
            ];
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
}
