{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [
          config.checks.pre-commit-check.enabledPackages
        ];
        inherit (config.checks.pre-commit-check) shellHook;
      };
    };
}
