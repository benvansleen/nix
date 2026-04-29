{ self, ... }:

{
  flake.modules.kubernetes.k3s = {
    imports = with self.modules.kubernetes; [
      cert-manager
      descheduler
      gateway
      nginx
      pihole
      searx
      tailscale-operator
    ];

    nixidy = {
      target.rootPath = "./manifests/k3s";
    };

    modules = {
      cert-manager.enable = true;
      descheduler.enable = true;
      gateway.enable = true;
      nginx.enable = true;
      pihole.enable = true;
      searx.enable = true;
      tailscale-operator.enable = true;
    };
  };
}
