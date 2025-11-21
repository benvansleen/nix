lib:
{
  nixpkgs,
  systems,
  ...
}@specialArgs:

let
  constants = import ./constants.nix;

  nixFilesInDir =
    dir:
    with lib;
    let
      allTrue = all id;
    in
    pipe dir [
      builtins.readDir
      (filterAttrs (
        name: filetype:
        allTrue [
          (!hasPrefix "." name)
          (
            (filetype == "directory")
            || allTrue [
              (filetype == "regular")
              (hasSuffix ".nix" name)
              (name != "default.nix")
            ]
          )
        ]
      ))
      (mapAttrsToList (name: _filetype: dir + ("/" + name)))
    ];
in
rec {
  inherit constants;

  importAll = dir: { imports = nixFilesInDir dir; };

  mkSystem =
    host: nixpkgs-config:
    lib.nixosSystem {
      inherit specialArgs;
      pkgs = import nixpkgs nixpkgs-config;
      modules = [
        ../modules/system
        ../hosts
        ../users
        host
      ];
    };

  allHomeModules =
    with lib;
    [ ../modules/home ]
    ++ (pipe specialArgs [
      (filterAttrs (_moduleName: module: module ? homeManagerModules))
      (mapAttrsToList (
        moduleName:
        {
          homeManagerModules ? { },
          homeModules ? { },
          ...
        }:
        homeModules.default or homeModules.${moduleName} or homeManagerModules.default
          or homeManagerModules.${moduleName} or homeManagerModules.${head (attrNames homeManagerModules)}
      ))
    ]);

  mkUser =
    {
      enable,
      user,
      extraHomeModules,
      extraConfig,
    }:
    extraConfig
    // {
      home-manager = enable {
        users.${user} = _: {
          imports = allHomeModules ++ extraHomeModules;
        };
      };
    };

  eachSystem =
    f:
    lib.genAttrs (import systems) (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      f pkgs pkgs.stdenv.hostPlatform.system
    );

  eachUser =
    f:
    with lib;
    let
      users = pipe ../users [
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
// (import ./tailscale.nix { inherit lib constants; })
