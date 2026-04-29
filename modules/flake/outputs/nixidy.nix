{ inputs, self, ... }:

{
  flake-file.inputs = {
    nixidy = {
      url = "github:arnarg/nixidy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixhelm = {
      url = "github:farcaller/nixhelm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  perSystem =
    {
      inputs',
      self',
      pkgs,
      system,
      ...
    }:
    {
      packages = {
        nixidy = inputs'.nixidy.packages.default;
        "generators/tailscale" = inputs'.nixidy.packages.generators.fromChartCRD {
          name = "tailscale";
          chart = inputs.nixhelm.chartsDerivations.${system}.tailscale.tailscale-operator;
        };
        "generators/cert-manager" = inputs'.nixidy.packages.generators.fromCRD {
          name = "cert-manager";
          src = pkgs.fetchFromGitHub {
            owner = "cert-manager";
            repo = "cert-manager";
            rev = "v1.20.2";
            hash = "sha256-JbQcRPPgjlvcOxnYID3zJq5CAqigI7HbbwHm5S+9r4E";
          };
          crds = [
            "deploy/crds/cert-manager.io_certificates.yaml"
            "deploy/crds/cert-manager.io_clusterissuers.yaml"
            "deploy/crds/cert-manager.io_issuers.yaml"
          ];
        };
        "generators/traefik" = inputs'.nixidy.packages.generators.fromChartCRD {
          name = "traefik";
          chart = inputs.nixhelm.chartsDerivations.${system}.traefik.traefik;
        };
      };

      legacyPackages = {
        nixidyEnvs.${system} = inputs.nixidy.lib.mkEnvs {
          inherit pkgs;
          charts = inputs.nixhelm.chartsDerivations.${system};
          envs = {
            k3s.modules = [ self.modules.kubernetes.k3s ];
          };
        };
      };

      apps = {
        generate = {
          type = "app";
          program =
            (pkgs.writeShellScript "generate-crds" /* sh */ ''
              set -eo pipefail

              cat ${self'.packages."generators/tailscale"} > generated/tailscale-operator.nix
              cat ${self'.packages."generators/cert-manager"} > generated/cert-manager.nix
              cat ${self'.packages."generators/traefik"} > generated/traefik.nix
            '').outPath;
        };
        update-unbound = {
          type = "app";
          program =
            (pkgs.writeShellScript "update-unbound" /* sh */ ''
              set -eo pipefail

              image_tar=${self.packages.aarch64-linux.unbound-image}
              exporter_image_tar=${self.packages.aarch64-linux.unbound-exporter-image}
              scp "$image_tar" "pi:/tmp/unbound-image.tar.gz"
              scp "$exporter_image_tar" "pi:/tmp/unbound-exporter-image.tar.gz"
              ssh root@pi "k3s ctr images import /tmp/unbound-image.tar.gz"
              ssh root@pi "k3s ctr images import /tmp/unbound-exporter-image.tar.gz"

              ssh root@pi "k3s ctr images list | grep -i unbound"
            '').outPath;
        };
      };
    };
}
