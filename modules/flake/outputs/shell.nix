{
  perSystem =
    {
      self',
      config,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          config.pre-commit.settings.enabledPackages
          self'.packages.nixidy
        ];
        inherit (config.pre-commit) shellHook;
      };
    };
}
