{ inputs, self, ... }:

{
  flake-file.inputs.nixidy.url = "github:arnarg/nixidy";
  flake-file.inputs.nixhelm.url = "github:farcaller/nixhelm";

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
              cat ${self'.packages."generators/traefik"} > generated/traefik.nix
            '').outPath;
        };
      };
    };
}
