{ inputs, ... }:

{
  flake.modules.nixos.base-host =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = with inputs.self.modules.nixos; [
        facter
        impermanence
        nix
        nixosCli
        inputs.self.modules.nixos."prometheus/client"
        sops
        tailscale
        users
      ];

      options.machine = with lib; {
        name = mkOption {
          type = types.str;
          default = "nixos";
          description = "The hostname of the machine";
        };
        allowUnfree = mkEnableOption "Allow unfree nixpkgs";
        powerful = mkEnableOption "Powerful machine configuration";
        desktop = mkEnableOption "Desktop machine configuration; enable gui apps";
      };

      config = {
        modules = {
          tailscale.enable = true;
          prometheus.client.enable = true;
        };

        environment = {
          systemPackages = with pkgs; [
            bat
            fd
            git
            htop-vim
            procs
            ripgrep

            # To use graphical wayland applications over ssh
            ## 1. Ensure `waypipe` is installed on both client and server
            ## 2. From client: `waypipe ssh <user>@<host> <command>`
            waypipe

            ((vim-full.override { }).customize {
              name = "vim";
              vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
                start = [
                  vim-nix
                  vim-lastplace
                ];
                opt = [ ];
              };
              vimrcConfig.customRC = ''
                imap jj <C-[>
                nmap ; :
                set nocompatible
                set backspace=indent,eol,start
                syntax on
              '';
            })
          ];

          variables = {
            EDITOR = "vim";
          };
        };

        networking = {
          hostName = config.machine.name;
          firewall = {
            enable = true;
          };
        };

        security = {
          doas = {
            enable = inputs.self.constants.privilege-escalation == "doas";
            extraRules = [
              {
                groups = [ "wheel" ];
                keepEnv = true;
                noPass = false;
                persist = true;
              }
            ];
          };
          sudo = {
            enable = inputs.self.constants.privilege-escalation == "sudo";
            execWheelOnly = true;
          };

          # Allows pipewire to get (soft) realtime
          rtkit.enable = true;
        };

        services = {
          dbus.implementation = "broker";
          fstrim.enable = true;
          openssh.settings.PermitRootLogin = "no";
          pipewire = {
            enable = true;
            alsa.enable = true;
            pulse.enable = true;
          };
        };

        systemd.oomd = {
          enable = true;
          enableRootSlice = true;
          enableSystemSlice = true;
          enableUserSlices = true;
        };

        system.activationScripts = {
          diffGens = ''
            ${lib.getExe pkgs.dix} /run/current-system "$systemConfig"
          '';
        };

        time.timeZone = "America/New_York";
        i18n = {
          defaultLocale = "en_US.UTF-8";
          extraLocaleSettings = {
            LC_ADDRESS = "en_US.UTF-8";
            LC_IDENTIFICATION = "en_US.UTF-8";
            LC_MEASUREMENT = "en_US.UTF-8";
            LC_MONETARY = "en_US.UTF-8";
            LC_NAME = "en_US.UTF-8";
            LC_NUMERIC = "en_US.UTF-8";
            LC_PAPER = "en_US.UTF-8";
            LC_TELEPHONE = "en_US.UTF-8";
            LC_TIME = "en_US.UTF-8";
          };
        };
      };
    };
}
