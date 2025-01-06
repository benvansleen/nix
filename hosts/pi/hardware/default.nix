{ nixos-facter-modules, pkgs, ... }:

{
  imports = [
    nixos-facter-modules.nixosModules.facter
  ];

  config = {
    facter.reportPath = ./facter.json;

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
      initrd.availableKernelModules = [
        "xhci_pci"
        "usbhid"
        "usb_storage"
      ];
      loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };
    };

    hardware.enableRedistributableFirmware = true;
  };
}
