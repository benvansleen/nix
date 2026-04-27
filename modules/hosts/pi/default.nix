{ self, ... }:

{
  flake.modules.nixos.pi = {
    imports = with self.modules.nixos; [
      base-host
      pi-configuration
      pi-disk
      pi-hardware

      self.modules.nixos."borgbackup/client"
      self.modules.nixos."borgbackup/server"
      caddy
      clonix
      containers
      grafana
      maybe
      pihole
      self.modules.nixos."prometheus/server"
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
