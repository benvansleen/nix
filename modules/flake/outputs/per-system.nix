{
  inputs,
  ...
}:
let
  localLib = import ../../../lib inputs;
in
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      run = import ../../../run {
        inherit pkgs;
        lib = localLib;
      };
      createApp = pkg: {
        type = "app";
        program = localLib.getExe pkg;
      };
      setPasswordFor = user: createApp (run.set-password-for user);
    in
    {
      apps =
        with localLib;
        (pipe run [
          (filterAttrs (name: value: (builtins.typeOf value) == "set" && !hasPrefix "override" name))
          (mapAttrs (_name: createApp))
        ])
        // (pipe { root = setPasswordFor "root"; } [
          (attrs: attrs // (eachUser setPasswordFor))
          (mapAttrs' (user: app: nameValuePair "set-password-for-${user}" app))
        ]);

      formatter = (inputs.treefmt-nix.lib.evalModule pkgs ../../../treefmt.nix).config.build.wrapper;

      checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = ../../../.;
        hooks = {
          check-added-large-files.enable = true;
          check-merge-conflicts.enable = true;
          detect-private-keys.enable = true;
          deadnix.enable = true;
          end-of-file-fixer.enable = true;
          flake-checker.enable = true;
          ripsecrets.enable = true;
          statix = {
            enable = true;
            settings.config = "statix.toml";
          };
          treefmt = {
            enable = true;
            packageOverrides.treefmt = config.formatter;
          };
          typos = {
            enable = true;
            settings = {
              diff = false;
              ignored-words = [
                "artic"
                "facter"
              ];
              exclude = "*.patch";
            };
          };
        };
      };

      devShells.default = pkgs.mkShell {
        buildInputs = [
          config.checks.pre-commit-check.enabledPackages
        ];
        inherit (config.checks.pre-commit-check) shellHook;
      };
    };
}
