{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  cfg = config.modules.crossplatform-builder;
in
{
  options.modules.crossplatform-builder = {
    enable = mkEnableOption "enable nixos builds for multiple platform targets";
  };

  config = mkIf cfg.enable {
    boot.binfmt.emulatedSystems = [
      "wasm32-wasi"
      "x86_64-windows"
      "aarch64-linux"
    ];
    systemd.services.nix-daemon.requires = [ "systemd-binfmt.service" ];
    # nix.settings.extra-sandbox-paths = [ "/run/binfmt" ];
    # systemd.services.nix-daemon.after = [ "systemd-binfmt.service" ];
  };
}
