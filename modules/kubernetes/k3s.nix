{ self, ... }:

{
  flake.modules.kubernetes.k3s = {
    imports = with self.modules.kubernetes; [
      nginx
      tailscale-operator
    ];

    nixidy = {
      target.rootPath = "./manifests/k3s";
    };

    modules = {
      nginx.enable = true;
      tailscale-operator.enable = true;
    };
  };
}
