{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = [
          config.pre-commit.settings.enabledPackages
        ];
        inherit (config.pre-commit) shellHook;
      };
    };
}
