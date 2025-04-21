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
  cfg = config.modules.tailscale;
in
{
  options.modules.tailscale = {
    enable = mkEnableOption "tailscale";
    authKeyFile = mkOption {
      type = types.str;
      default = "";
      description = "Path to the Tailscale authentication key file";
    };
    tailscale-up-extra-args = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments to pass to tailscale up";
    };
  };

  config = mkIf cfg.enable {
    modules.impermanence.persistedDirectories = [
      "/var/lib/tailscale"
    ];

    environment.systemPackages = with pkgs; [
      tailscale
    ];

    # https://github.com/tailscale/tailscale/issues/4432
    networking.firewall.checkReversePath = "loose";

    services.tailscale.enable = true;
    systemd.services.tailscale-autoconnect = {
      description = "Automatically connect to Tailscale VPN";

      # make sure tailscale is running before trying to connect
      after = [
        "tailscaled.service"
      ];
      wants = [
        "tailscaled.service"
      ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";
      script = with pkgs; ''
        # wait for tailscaled to settle
        # sleep 2

        # check if we are already authenticated
        status="$(${lib.getExe tailscale} status --json | ${lib.getExe jq} -r .BackendState)"

        # if we are already authenticated, do nothing
        if [ "$status" = "Running" ]; then
          exit 0
        fi

        ${lib.getExe tailscale} up --auth-key "file:${cfg.authKeyFile}"
        ${lib.getExe tailscale} set ${lib.concatStringsSep " " cfg.tailscale-up-extra-args}
      '';
    };
  };

}
