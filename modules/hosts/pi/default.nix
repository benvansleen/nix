{ inputs, ... }:

{
  flake.modules.nixos.pi = {
    imports = with inputs.self.modules.nixos; [
      base-host
      pi-configuration
      pi-disk
      pi-hardware

      caddy
      clonix
      containers
      grafana
      maybe
      nixosCli
      pihole
      inputs.self.modules.nixos."prometheus/client"
      inputs.self.modules.nixos."prometheus/server"
      searx
      unbound
    ];

    config.machine = {
      name = "pi";
      desktop = false;
      powerful = false;
      allowUnfree = false;
    };
  };
}
