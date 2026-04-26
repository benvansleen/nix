{ lib, ... }:

{
  flake.overlays.lib = final: _prev: {
    optimizeWithFlag =
      pkg: flag:
      pkg.overrideAttrs (old: {
        NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " ${flag}";
      });
    optimizeWithFlags = pkg: flags: lib.foldl (pkg: flag: final.optimizeWithFlag pkg flag) pkg flags;
    optimizeForThisHost =
      {
        pkg,
        extraFlags ? [ ],
      }:
      final.optimizeWithFlags pkg (
        [
          "-O3"
          "-march=native"
          "-fPIC"
        ]
        ++ extraFlags
      );
    withDebuggingCompiled = pkg: final.optimizeWithFlag pkg "-DDEBUG";
    optimizeForThisHostIfPowerful =
      {
        config,
        pkg,
        extraFlags ? [ ],
      }:
      if config.machine.powerful then final.optimizeForThisHost { inherit pkg extraFlags; } else pkg;
  };
}
