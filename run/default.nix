{
  pkgs,
  lib,
  colmena,
  ...
}:

let
  colmena-bin = "RUST_LOG=error ${lib.getExe colmena.packages.${pkgs.system}.colmena}";
in
{
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
      nix run .#rebuild-diff
    '';
  };

  apply = pkgs.writeShellApplication {
    name = "apply";
    text = ''
      nix flake update secrets
      ${colmena-bin} apply "''${1:-switch}"
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
    text = with pkgs lib; ''
      [ -z "$1" ] && printf "Must provide a host!" && exit 0
      HOST="$1"
      ${getExe disko} --mode disko "/nixos-config/hosts/$HOST/disko-config.nix"
      ${getExe nixos-facter} -o "/nixos-config/hosts/$HOST/facter.json"
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
      text = with pkgs lib; ''
        PASSWORD_FILE=${file}

        read -rp "New password: " password
        if [ -z "$password" ]
        then
            echo "Password cannot be empty!"
            exit 1
        fi

        SOPS_AGE_KEY=$(${need-privileged-execution} ${getExe ssh-to-age} -i ${keyfile} -private-key)
        export SOPS_AGE_KEY
        if [ -e $PASSWORD_FILE ]
        then
            hash=$(${getExe mkpasswd} "$password" -m sha-512)
            ${getExe sops} set "$PASSWORD_FILE" '["data"]' "\"$hash\""
            echo "Password will update after next system rebuild"
            echo "Be sure to push to the \`secrets\` remote repository"
        else
            echo "$PASSWORD_FILE not found!"
        fi
      '';
    };
}
