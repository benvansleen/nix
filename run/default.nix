{
  pkgs,
  lib,
  colmena,
  ...
}:

let
  colmena-bin = "RUST_LOG=error ${
    lib.getExe colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
  }";
in
rec {
  default = rebuild;

  rebuild-diff = pkgs.writers.writeBabashkaBin "rebuild-diff-closures" { } ''
    (ns script
      (:require [babashka.process :refer [shell]]
                [babashka.fs :as fs]
                [clojure.string :as str]))

    (let [current-generation
          (-> (shell {:out :string} "readlink /nix/var/nix/profiles/system")
              :out
              (#(str/split % #"-"))
              second
              Integer/parseInt)
          to-path #(str "/nix/var/nix/profiles/system-" % "-link")
          previous-generation (to-path (- current-generation 1))]
      (when (fs/exists? previous-generation)
        (println (str "Version "
                      previous-generation " -> " current-generation ":"))
        (shell "${lib.getExe pkgs.dix}"
               previous-generation
               (to-path current-generation))))
  '';

  boot-partition-space-remaining = pkgs.writers.writeBashBin "boot-partition-space-remaining" { } ''
    echo "/boot utilization: $(df -P | grep /boot | awk '{ print $5 }')"
  '';

  all = pkgs.writeShellApplication {
    name = "all";
    text = ''
      nix run .#build
      nix run .#rebuild -- "''${1:-switch}"
      nix run .#apply -- "''${1:-switch}"
    '';
  };

  rebuild = pkgs.writeShellApplication {
    name = "rebuild";
    text = ''
      mode="''${1:-switch}"
      [ "$mode" = 'switch' ] && nix run .#boot-partition-space-remaining
      nix flake update secrets
      ${colmena-bin} apply-local "$mode" --sudo
    '';
  };

  apply = pkgs.writeShellApplication {
    name = "apply";
    text = ''
      nix flake update secrets
      ${colmena-bin} apply -v "''${1:-switch}"
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
      [ -z "$1" ] && printf "Must provide a host!" && exit 1
      HOST="$1"
      ${lib.getExe pkgs.disko} --mode disko "/nixos-config/hosts/$HOST/disko-config.nix"
      ${lib.getExe pkgs.nixos-facter} -o "/nixos-config/hosts/$HOST/facter.json"
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
      text = with lib; ''
        PASSWORD_FILE=${file}

        read -rp "New password: " password
        if [ -z "$password" ]
        then
            echo "Password cannot be empty!"
            exit 1
        fi

        SOPS_AGE_KEY=$(${need-privileged-execution} ${getExe pkgs.ssh-to-age} -i ${keyfile} -private-key)
        export SOPS_AGE_KEY
        if [ -e $PASSWORD_FILE ]
        then
            hash=$(${getExe pkgs.mkpasswd} "$password" -m sha-512)
            ${getExe pkgs.sops} set "$PASSWORD_FILE" '["data"]' "\"$hash\""
            echo "Password will update after next system rebuild"
            echo "Be sure to push to the \`secrets\` remote repository"
        else
            echo "$PASSWORD_FILE not found!"
        fi
      '';
    };

  rebuild-facter-report = pkgs.writeShellApplication {
    name = "rebuild-facter-report";
    runtimeInputs = with pkgs; [ sops ];
    text = ''
      HOST="''${1:-$(hostname)}"
      DEST="./secrets/hosts/$HOST/facter.json"

      if [[ "$HOST" == "$(hostname)" ]]; then
          ${lib.constants.privilege-escalation} nix run nixpkgs#nixos-facter -- -o "$DEST"
      else
          ${colmena-bin} exec -v --on "$HOST" \
            ${lib.constants.privilege-escalation} nix run nixpkgs#nixos-facter -- -o "/tmp/facter.json"
          scp "root@$HOST:/tmp/facter.json" "$DEST"
      fi
    '';
  };
}
