{ self, ... }:

{
  flake.modules.kubernetes.k3s = {
    imports = with self.modules.kubernetes; [
      cert-manager
      gateway
      nginx
      pihole
      tailscale-operator
    ];

    nixidy = {
      target.rootPath = "./manifests/k3s";
    };

    modules = {
      cert-manager.enable = true;
      gateway.enable = true;
      nginx.enable = true;
      pihole.enable = true;
      tailscale-operator.enable = true;
    };
  };
}
