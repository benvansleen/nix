{
  pkgs,
  nixos-facter-modules,
  disko,
  ...
}:

{
  imports = [
    nixos-facter-modules.nixosModules.facter
    {
      config.facter.reportPath = ./facter.json;
    }

    disko.nixosModules.disko
    ./disko-config.nix
  ];

  modules.system.impermanence.enable = true;

  nix.settings.max-jobs = 4;

  boot.loader = {
    grub = {
      enable = true;
      useOSProber = true;
    };
  };

  networking = {
    hostName = "qemu";
    nftables.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  ## Without this, rebuilding os hangs
  systemd = {
    services.NetworkManager-wait-online.enable = false;
    network.wait-online.enable = false;
  };

  # Select internationalisation properties.
  # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "us";
  #   variant = "";
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.ben = import ../../users/ben { inherit pkgs; };
  # users.users.ben = {
  #   isNormalUser = true;
  #   description = "ben";
  #   extraGroups = [ "networkmanager" "wheel" ];
  #   home =
  #   # packages = with pkgs; [];
  # };

  # Allow unfree packages

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # networking.firewall.allowedTCPPorts = [ 22 ];
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };

    irqbalance.enable = true;
    tlp.enable = false;
    thermald.enable = true;
  };

  # Experimental
  ## Currently get `mkcomposefs: command not found` error
  # system.etc.overlay.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
