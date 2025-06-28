{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.firefox;

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
  options.modules.firefox = {
    enable = mkEnableOption "firefox";
  };

  config = mkIf cfg.enable {
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
}
