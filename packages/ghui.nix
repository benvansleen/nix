{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  bun,
  nodejs,
  gh,
  git,
  makeBinaryWrapper,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  node_modules ? null,
  ...
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ghui";
  version = "0.4.7";

  src = fetchFromGitHub {
    owner = "kitlangton";
    repo = "ghui";
    rev = "v${finalAttrs.version}";
    hash = "sha256-ZM4FGO0a7Mtmtvtz8mpe1eApvFDcV/x0c3Pw3PEJkdc=";
  };

  node_modules =
    if node_modules != null then
      node_modules
    else
      stdenvNoCC.mkDerivation {
        pname = "ghui-node-modules";
        inherit (finalAttrs) version src;

        nativeBuildInputs = [ bun ];

        configurePhase = ''
          runHook preConfigure

          export HOME=$TMPDIR
          export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache

          runHook postConfigure
        '';

        buildPhase = ''
          runHook preBuild

          bun install --frozen-lockfile
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -R node_modules packages $out/
          runHook postInstall
        '';

        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        outputHash = "sha256-pD941VGUY3gt+CHNPhsce1MqsXUbgmE435itwNtO3xo=";
        dontCheckForBrokenSymlinks = true;
      };

  nativeBuildInputs = [
    bun
    nodejs
    makeBinaryWrapper
    writableTmpDirAsHomeHook
  ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/. .
    chmod -R u+w node_modules packages/*/node_modules
    patchShebangs node_modules
    patchShebangs packages/*/node_modules

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    bun run dev/build-standalone.ts linux-${
      if stdenvNoCC.hostPlatform.isAarch64 then "arm64" else "x64"
    }
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/release/linux-${
      if stdenvNoCC.hostPlatform.isAarch64 then "arm64" else "x64"
    }/ghui $out/bin/ghui
    wrapProgram $out/bin/ghui \
      --prefix PATH : ${
        lib.makeBinPath [
          gh
          git
        ]
      }

    runHook postInstall
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  doInstallCheck = stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform;
  versionCheckProgramArg = "--version";
  dontCheckForBrokenSymlinks = true;

  propagatedUserEnvPkgs = [
    gh
  ];

  meta = {
    description = "Terminal UI for GitHub pull requests";
    homepage = "https://github.com/kitlangton/ghui";
    license = lib.licenses.mit;
    mainProgram = "ghui";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
