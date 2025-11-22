{ pkgs, ... }:

{
  config = {
    nixpkgs.hostPlatform.system = "aarch64-linux";

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
