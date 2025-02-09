{ pkgs, colmena, ... }:

let
  colmena-bin = "RUST_LOG=error ${
    colmena.packages.${pkgs.system}.colmena
  }/bin/colmena --experimental-flake-eval";
in
{
  rebuild = pkgs.writeShellApplication {
    name = "rebuild";
    text = ''
      nix flake update secrets
      ${colmena-bin} apply-local "''${1:-switch}" --sudo
    '';
  };

  apply = pkgs.writeShellApplication {
    name = "apply";
    text = ''
      nix flake update secrets
      ${colmena-bin} apply "''${1:-switch}" --evaluator streaming

      # Toggle tailscale dns resolution to prevent /etc/resolv.conf from being clobbered by nix
      ${colmena-bin} exec --on pi "tailscale set --accept-dns=false && tailscale set --accept-dns=true"
    '';
  };

  build = pkgs.writeShellApplication {
    name = "build";
    text = ''
      ${colmena-bin} build
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
      file = "./secrets/users/${user}/password.sops";
      keyfile = if user == "root" then "/etc/ssh/ssh_host_ed25519_key" else "~/.ssh/master";
      need-privileged-execution = if user == "root" then "sudo" else "";
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

        SOPS_AGE_KEY=$(${need-privileged-execution} ${pkgs.ssh-to-age}/bin/ssh-to-age -i ${keyfile} -private-key)
        export SOPS_AGE_KEY
        if [ -e $PASSWORD_FILE ]
        then
            hash=$(${pkgs.mkpasswd}/bin/mkpasswd "$password" -m sha-512)
            ${pkgs.sops}/bin/sops set "$PASSWORD_FILE" '["data"]' "\"$hash\""
            echo "Password will update after next system rebuild"
            echo "Be sure to push to the \`secrets\` remote repository"
        else
            echo "$PASSWORD_FILE not found!"
        fi
      '';
    };
}
