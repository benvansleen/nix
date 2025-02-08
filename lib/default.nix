lib: overlays:
{
  nixpkgs,
  nixpkgs-stable,
  systems,
  secrets,
  ...
}@inputs:

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
    system: extraModules:
    (
      let
        pkgs-config = { inherit system overlays; };
        pkgs-stable = import nixpkgs-stable pkgs-config;
        pkgs-unfree = import nixpkgs (
          pkgs-config
          // {
            config.allowUnfree = true;
          }
        );
      in
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgs-stable pkgs-unfree secrets;
        } // inputs;
        modules = [
          {
            nixpkgs.config = pkgs-config;
          }
          ../modules/system
          ../hosts
          ../users
        ] ++ extraModules;
      }
    );

  allHomeModules =
    with lib;
    [ ../modules/home ]
    ++ (pipe inputs [
      (filterAttrs (_moduleName: module: module ? homeManagerModules))
      (mapAttrsToList (
        moduleName:
        { homeManagerModules, ... }:
        homeManagerModules.default or homeManagerModules.${moduleName}
          or homeManagerModules.${head (attrNames homeManagerModules)}
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
      f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
      }
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
