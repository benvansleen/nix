{ self, ... }:

{
  flake.modules.kubernetes.k3s = {
    imports = with self.modules.kubernetes; [
      cert-manager
      gateway
      nginx
      tailscale-operator
    ];

    nixidy = {
      target.rootPath = "./manifests/k3s";
    };

    modules = {
      cert-manager.enable = true;
      gateway.enable = true;
      nginx.enable = true;
      tailscale-operator.enable = true;
    };
  };
}
