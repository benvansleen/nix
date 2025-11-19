# From https://github.com/vincentbernat/caddy-nix/blob/main/examples/xcaddy-src/flake.nix
# Will be unnecessary once `caddy-tailscale` breakage on `nixpkgs-unstable`
# is resolved
_final: prev: rec {
  caddy = prev.caddy.overrideAttrs (oldAttrs: {
    passthru = (oldAttrs.passthru or { }) // {
      withPlugins =
        {
          plugins,
          hash ? prev.lib.fakeHash,
        }:
        caddy.overrideAttrs (
          finalAttrs: _prevAttrs:
          let
            inherit (finalAttrs) version;
          in
          {
            vendorHash = null;
            subPackages = [ "." ];
            src = prev.stdenvNoCC.mkDerivation {
              pname = "caddy-src-with-xcaddy";
              inherit version;

              nativeBuildInputs = [
                prev.go
                prev.xcaddy
                prev.cacert
              ];
              dontUnpack = true;
              buildPhase =
                let
                  withArgs = prev.lib.concatMapStrings (plugin: "--with ${plugin} ") plugins;
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
  });
}
