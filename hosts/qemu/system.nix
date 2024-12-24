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

  boot = {
    binfmt.emulatedSystems = [
      "wasm32-wasi"
      "x86_64-windows"
      "aarch64-linux"
    ];
    initrd.systemd.enable = true;
    loader.grub = {
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

  environment.systemPackages = with pkgs; [ ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services = {
    displayManager.ly = {
      enable = true;
      settings = { };
    };

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
