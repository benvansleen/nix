{ inputs, ... }:

{
  flake-file.inputs.impermanence = {
    url = "github:nix-community/impermanence";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
    };
  };

  flake = {
    modules.nixos.impermanence =
      { config, lib, ... }:
      {
        imports = [ inputs.impermanence.nixosModules.impermanence ];

        options.persist = {
          root = lib.mkOption {
            type = lib.types.str;
            default = "/persist";
            example = "/nix/persist";
            description = "where to mount persistent storage";
          };
          directories = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            example = [
              "/var/log"
              "/var/lib/bluetooth"
            ];
            description = "additional directories to persist";
          };
          files = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = "additional files to persist";
          };
        };

        config = {
          fileSystems.${config.persist.root} = {
            neededForBoot = true;
            options = [ "noexec" ];
          };

          # Ensure all necessary state is preserved according to nixos manual:
          # https://nixos.org/manual/nixos/stable/#ch-system-state
          environment.persistence.${config.persist.root} = {
            enable = true;
            hideMounts = true;
            directories = [
              "/var/log"
              "/var/lib/bluetooth"
              "/var/lib/nixos"
              "/var/lib/systemd"
              "/var/log/journal"
              "/etc/NetworkManager/system-connections"
            ]
            ++ config.persist.directories;
            files = [
              "/etc/machine-id"
              # "/etc/passwd"
              # "/etc/group"
              # "/etc/shadow"
              # "/etc/gshadow"
              # "/etc/subuid"
              # "/etc/subgid"

              # Investigate declarative ssh key config
              "/etc/ssh/ssh_host_ed25519_key"
              "/etc/ssh/ssh_host_ed25519_key.pub"
              "/etc/ssh/ssh_host_rsa_key"
              "/etc/ssh/ssh_host_rsa_key.pub"
            ]
            ++ config.persist.files;
          };

          # When /etc is not persisted, sudo lectures on first use every boot
          security.sudo.extraConfig = ''
            Defaults lecture=never
          '';

        };
      };

    modules.homeManager.impermanence =
      {
        config,
        osConfig,
        lib,
        ...
      }:
      {
        options.persist = {
          files = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = "Files to persist";
          };

          directories = lib.mkOption {
            type =
              with lib.types;
              listOf (oneOf [
                str
                (attrsOf str)
              ]);
            default = [ ];
            description = "Directories to persist";
          };
        };
        config =
          let
            normalize = lib.strings.removePrefix "${config.home.homeDirectory}/";
            files = map normalize config.persist.files;
            directories = map normalize config.persist.directories;
          in
          {
            home = {
              persistence.${osConfig.persist.root} = {
                inherit directories;
                files = [ ".ssh/known_hosts" ] ++ files;
              };

              activation."rm-persisted-files" = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
                for f in ${
                  toString (lib.map (f: f.filePath) config.home.persistence.${osConfig.persist.root}.files)
                }; do
                    echo "Removing $f"
                    rm $f || true
                done
              '';
            };
          };
      };
  };
}
