{ pkgs, nixos-facter-modules, disko, impermanence, ... }:

{

  imports = [
	nixos-facter-modules.nixosModules.facter {
	  config.facter.reportPath = ./facter.json;
	}

    disko.nixosModules.disko (import ./disko-config.nix)

	impermanence.nixosModules.impermanence

	# ./hardware-configuration.nix
  ];

  environment.persistence."/nix/persist" = {
	enable = true;
	hideMounts = true;
	directories = [
	  "/var/log"
      "/var/db/sudo"
	  "/var/lib/bluetooth"
	  "/var/lib/nixos"
	  "/var/lib/systemd/coredump"
	  "/etc/NetworkManager/system-connections"
	];
	files = [
      "/etc/machine-id"

	  # Investigate declarative ssh key config
	  "/etc/ssh/ssh_host_ed25519_key"
	  "/etc/ssh/ssh_host_ed25519_key.pub"
	  "/etc/ssh/ssh_host_rsa_key"
	  "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };


  nix.settings.max-jobs = 4;

  # Bootloader.
  boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "qemu";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  ## Without this, rebuilding os hangs
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.network.wait-online.enable = false;

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

  networking.firewall.allowedTCPPorts = [ 22 ];
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
  services.tlp.enable = false;
  services.thermald.enable = true;
  services.irqbalance.enable = true;

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
