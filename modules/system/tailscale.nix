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
    systemd.services.tailscale-autoconnect =
      let
        operator-flags =
          with lib;
          pipe config.users.groups.wheel.members [
            (map (user: "--operator=${user}"))
            (concatStringsSep " ")
          ];
      in
      {
        description = "Automatically connect to Tailscale VPN";

        after = [
          "tailscaled.service"
        ];
        wants = [
          "tailscaled.service"
        ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig.Type = "oneshot";
        script = with pkgs; ''
          # check if we are already authenticated
          status="$(${lib.getExe tailscale} status --json | ${lib.getExe jq} -r .BackendState)"

          # if we are already authenticated, do nothing
          if [ "$status" = "Running" ]; then
            exit 0
          fi

          ${lib.getExe tailscale} up --auth-key "file:${cfg.authKeyFile}" --reset
          ${lib.getExe tailscale} set ${lib.concatStringsSep " " cfg.tailscale-up-extra-args}
          ${lib.getExe tailscale} set ${operator-flags}
        '';
      };
  };

}
