{
  nixpkgs,
  home-manager,
  ...
}:

let
  constants = import ./constants.nix;
  lib' =
    lib:
    rec {
      inherit constants;

      eachUser =
        f:
        with lib;
        let
          users = pipe ../modules/users [
            builtins.readDir
            (filterAttrs (_name: filetype: (filetype == "directory")))
            (mapAttrsToList (name: _filetype: name))
          ];
        in
        genAttrs users f;

      optimizeWithFlag =
        pkg: flag:
        pkg.overrideAttrs (old: {
          NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " ${flag}";
        });
      optimizeWithFlags = pkg: flags: lib.foldl (pkg: flag: optimizeWithFlag pkg flag) pkg flags;
      optimizeForThisHost =
        {
          pkg,
          extraFlags ? [ ],
        }:
        optimizeWithFlags pkg (
          [
            "-O3"
            "-march=native"
            "-fPIC"
          ]
          ++ extraFlags
        );
      withDebuggingCompiled = pkg: optimizeWithFlag pkg "-DDEBUG";
      optimizeForThisHostIfPowerful =
        {
          config,
          pkg,
          extraFlags ? [ ],
        }:
        if config.machine.powerful then optimizeForThisHost { inherit pkg extraFlags; } else pkg;
    }
    // (import ./tailscale.nix { inherit lib constants; });
in
nixpkgs.lib.extend (final: _prev: home-manager.lib // (lib' final))
