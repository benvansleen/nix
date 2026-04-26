{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      apps = {
        rebuild-facter-report = {
          type = "app";
          program = pkgs.writeShellApplication {
            name = "rebuild-facter-report";
            runtimeInputs = with pkgs; [ sops ];
            text = ''
              HOST="''${1:-$(hostname)}"
              DEST="./secrets/hosts/$HOST/facter.json"

              if [[ "$HOST" == "$(hostname)" ]]; then
                  ${inputs.self.constants.privilege-escalation} nix run nixpkgs#nixos-facter -- -o "$DEST"
              else
                  ssh "root@$HOST" nix run nixpkgs#nixos-facter -- -o "/tmp/facter.json"
                  scp "root@$HOST:/tmp/facter.json" "$DEST"
              fi
            '';
          };
        };
      };
    };
}
