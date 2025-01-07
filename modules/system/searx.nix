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
  cfg = config.modules.system.searx;
in
{
  options.modules.system.searx = {
    enable = mkEnableOption "searx";
    port = mkOption {
      type = types.port;
    };
  };
  config = mkIf cfg.enable {
    services.searx = {
      enable = true;
      package = pkgs.searxng;
      redisCreateLocally = false;
      runInUwsgi = false;
      settings = {
        server = {
          bind_address = "localhost";
          inherit (cfg) port;
          secret_key = "TODO";
        };
        search.formats = [
          "html"
          "json"
        ];
        ui = {
          default_locale = "en";
          query_in_title = false;
          infinite_scroll = true;
          center_alignment = true;
          default_theme = "simple";
          theme_args.simple_style = "auto";
          hotkeys = "vim";
        };
        enabled_plugins = [
          "Basic Calculator"
          "Hostnames plugin"
          "Unit converter plugin"
          "Tracker URL remover"
        ];
        engines = lib.mapAttrsToList (name: value: { inherit name; } // value) {
          "1x".disabled = true;
          "apple maps".disabled = false;
          "artic".disabled = true;
          "bing images".disabled = true;
          "bing videos".disabled = true;
          "bing".disabled = true;
          "brave".disabled = false;
          "brave.images".disabled = false;
          "brave.news".disabled = false;
          "brave.videos".disabled = false;
          "cloudflareai".disabled = true;
          "crates.io".disabled = false;
          "crowdview".disabled = false;
          "curlie".disabled = true;
          "currency".disabled = false;
          "dailymotion".disabled = true;
          "ddg definitions".disabled = false;
          "deviantart".disabled = true;
          "dictzone".disabled = true;
          "duckduckgo images".disabled = false;
          "duckduckgo news".disabled = false;
          "duckduckgo videos".disabled = false;
          "duckduckgo".disabled = false;
          "flickr".disabled = true;
          "gitlab".disabled = false;
          "github".disbaled = false;
          "google".disabled = false;
          "google images".disabled = false;
          "google news".disabled = false;
          "google play movies".disabled = true;
          "google videos".disabled = false;
          "imgur".disabled = true;
          "invidious".disabled = true;
          "library of congress".disabled = false;
          "libretranslate".disabled = false;
          "lingva".disabled = true;
          "material icons".disabled = true;
          "mojeek".disabled = false;
          "mwmbl".disabled = true;
          "mymemory translated".disabled = true;
          "odysee".disabled = true;
          "openverse".disabled = true;
          "peertube".disabled = true;
          "pinterest".disabled = true;
          "piped".disabled = true;
          "qwant images".disabled = true;
          "qwant videos".disabled = true;
          "qwant".disabled = false;
          "rumble".disabled = true;
          "sepiasearch".disabled = true;
          "startpage".disabled = true;
          "svgrepo".disabled = true;
          "unsplash".disabled = true;
          "vimeo".disabled = true;
          "wallhaven".disabled = true;
          "wikibooks".disabled = true;
          "wikicommons.images".disabled = true;
          "wikidata".disabled = true;
          "wikipedia".disabled = false;
          "wikiquote".disabled = true;
          "wikisource".disabled = true;
          "wikispecies".disabled = true;
          "wikiversity".disabled = true;
          "wikivoyage".disabled = true;
          "wolframalpha".disabled = true;
          "yacy images".disabled = true;
          "youtube".disabled = false;
        };
      };
    };
  };
}
