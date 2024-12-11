{
  install-nix = pkgs: pkgs.writeShellApplication {
    name = "install-nix";
    runtimeInputs = with pkgs; [];
    # TODO: add facter configuration command
    text = ''
      nix run github:nix-community/disko/latest -- --mode disko /nixos-config/hosts/qemu/disko-config.nix
      nixos-install --flake /nixos-config#qemu
    '';
  };

  set-password-for = pkgs: file: pkgs.writeShellApplication {
    name = "set-password";
    runtimeInputs = with pkgs; [ sops ];
    text = ''
      PASSWORD_FILE=${file}

      read -rp "New password: " password
      if [ -e $PASSWORD_FILE ]
      then
          hash=$(${pkgs.mkpasswd}/bin/mkpasswd "$password" -m sha-512)
          sops set "$PASSWORD_FILE" '["data"]' "\"$hash\""
          echo "Password will update after next system rebuild"
      else
          echo "$PASSWORD_FILE not found!"
      fi
    '';
  };

}
