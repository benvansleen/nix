{
  lib,
  stdenvNoCC,
  pkgs,
  go,
  xcaddy,
  cacert,
  ...
}:

pkgs.caddy.overrideAttrs (oldAttrs: {
  passthru = (oldAttrs.passthru or { }) // {
    withPlugins =
      {
        plugins,
        hash ? lib.fakeHash,
        ...
      }:
      pkgs.caddy.overrideAttrs (
        finalAttrs: _prevAttrs:
        let
          inherit (finalAttrs) version;
        in
        {
          vendorHash = null;
          subPackages = [ "." ];
          src = stdenvNoCC.mkDerivation {
            pname = "caddy-src-with-xcaddy";
            inherit version;

            nativeBuildInputs = [
              go
              xcaddy
              cacert
            ];
            dontUnpack = true;
            buildPhase =
              let
                withArgs = lib.concatMapStrings (plugin: "--with ${plugin} ") plugins;
              in
              /* sh */ ''
                export GOCACHE=$TMPDIR/go-cache
                export GOPATH="$TMPDIR/go"
                XCADDY_SKIP_BUILD=1 TMPDIR="$PWD" xcaddy build v${version} ${withArgs}
                (cd buildenv* && go mod vendor)
              '';
            installPhase = ''
              mv buildenv* $out
            '';

            # Fixed derivation with hash
            outputHashMode = "recursive";
            outputHash = hash;
            outputHashAlgo = "sha256";
          };
        }
      );
  };
})
