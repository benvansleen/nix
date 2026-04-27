{ inputs, ... }:

{
  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";

  flake.modules.nixos.pi-hardware = {
    imports = [
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ];

    config = {
      nixpkgs.hostPlatform.system = "aarch64-linux";

      boot.kernel.sysctl = {
        "vm.mmap_rnd_bits" = 18;
      };
    };
  };
}
