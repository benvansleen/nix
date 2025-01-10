{ pkgs, ... }:

{
  rebuild = pkgs.writeShellApplication {
    name = "rebuild";
    text = ''
      ${pkgs.nh}/bin/nh os "''${1:-switch}" .
    '';
  };

  install-nixos = pkgs.writeShellApplication {
    name = "install-nixos";
    text = ''
      [ -z "$1" ] && printf "Must provide a host!" && exit 0
      HOST="$1"
      ${pkgs.disko}/bin/disko --mode disko "/nixos-config/hosts/$HOST/disko-config.nix"
      ${pkgs.nixos-facter}/bin/nixos-facter -o "/nixos-config/hosts/$HOST/facter.json"
      nixos-install --flake "/nixos-config#$HOST"
    '';
  };

  set-password-for =
    user:
    let
      file = if user == "root" then "./secrets/root-password.sops" else "./users/${user}/password.sops";
    in
    pkgs.writeShellApplication {
      name = "set-password";
      runtimeInputs = with pkgs; [ sops ];
      text = ''
        PASSWORD_FILE=${file}

        read -rp "New password: " password
        if [ -z "$password" ]
        then
            echo "Password cannot be empty!"
            exit 1
        fi

        if [ -e $PASSWORD_FILE ]
        then
            hash=$(${pkgs.mkpasswd}/bin/mkpasswd "$password" -m sha-512)
            ${pkgs.sops}/bin/sops set "$PASSWORD_FILE" '["data"]' "\"$hash\""
            echo "Password will update after next system rebuild"
        else
            echo "$PASSWORD_FILE not found!"
        fi
      '';
    };

}
