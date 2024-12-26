{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.home.firefox;
in
{
  options.modules.home.firefox = {
    enable = mkEnableOption "firefox";
  };

  config = mkIf cfg.enable {
    impermanence.persistedDirectories = [
      ".mozilla"
      "@cache@/mozilla"
    ];

    programs.firefox = {
      enable = true;
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
