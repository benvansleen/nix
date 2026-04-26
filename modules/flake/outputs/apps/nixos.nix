{
  perSystem =
    { pkgs, lib, ... }:
    {
      apps = {
        rebuild-diff = {
          type = "app";
          program = pkgs.writers.writeBabashkaBin "rebuild-diff-closures" { } /* clojure */ ''
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
                  previous-generation (to-path (- current-generation 1))
                  current-generation (to-path current-generation)]
              (when (fs/exists? previous-generation)
                (println (str "Version "
                              previous-generation " -> " current-generation ":"))
                (shell "${lib.getExe pkgs.dix}" previous-generation current-generation)))
          '';
        };

        boot-partition-space-remaining = {
          type = "app";
          program = pkgs.writers.writeBashBin "boot-partition-space-remaining" { } /* sh */ ''
            echo "/boot utilization: $(df -P | grep /boot | awk '{ print $5 }')"
          '';
        };

        install-nixos = {
          type = "app";
          program = pkgs.writeShellApplication {
            name = "install-nixos";
            text = ''
              [ -z "$1" ] && printf "Must provide a host!" && exit 1
              HOST="$1"
              ${lib.getExe pkgs.disko} --mode disko "/nixos-config/hosts/$HOST/disko-config.nix"
              ${lib.getExe pkgs.nixos-facter} -o "/nixos-config/hosts/$HOST/facter.json"
              nixos-install --flake "/nixos-config#$HOST"
            '';
          };
        };
      };
    };
}

#   ## TODO: migrate to nixos-cli
#   # default = rebuild;
#
#
#
#   all =
#     { pkgs, ... }:
#     pkgs.writeShellApplication {
#       name = "all";
#       text = ''
#         nix run .#build
#         nix run .#rebuild -- "''${1:-switch}"
#         nix run .#apply -- "''${1:-switch}"
#       '';
#     };
#
#   # rebuild =
#   #   { pkgs, ... }:
#   #   pkgs.writeShellApplication {
#   #     name = "rebuild";
#   #     text = ''
#   #       mode="''${1:-switch}"
#   #       [ "$mode" = 'switch' ] && nix run .#boot-partition-space-remaining
#   #       nix flake update secrets
#   #       ${colmena-bin} apply-local "$mode" --sudo
#   #     '';
#   #   };
#
#   # apply =
#   #   { pkgs, ... }:
#   #   pkgs.writeShellApplication {
#   #     name = "apply";
#   #     text = ''
#   #       nix flake update secrets
#   #       ${colmena-bin} apply -v "''${1:-switch}"
#   #     '';
#   #   };
#
#   # build =
#   #   { pkgs, ... }:
#   #   pkgs.writeShellApplication {
#   #     name = "build";
#   #     text = ''
#   #       ${colmena-bin} build
#   #     '';
#   #   };
# };
