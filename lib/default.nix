{
  nixpkgs,
  home-manager,
  systems,
  ...
}@specialArgs:

let
  constants = import ./constants.nix;
  lib' =
    lib:
    let
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
        overlays: host:
        lib.nixosSystem {
          inherit specialArgs;
          modules = [
            { nixpkgs = { inherit overlays; }; }
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
          (filterAttrs (
            moduleName: module:
            ## The Home Manager flake outputs are deprecated!
            ## The Home Manager module will be automatically imported by the NixOS
            ## module. Please remove any manual imports.
            ## See https://github.com/nix-community/impermanence?tab=readme-ov-file#home-manager
            ## for updated usage instructions.
            moduleName != "impermanence" && module ? homeManagerModules
          ))
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
            users.${user} = {
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
    // (import ./tailscale.nix { inherit lib constants; });
in
nixpkgs.lib.extend (final: _prev: home-manager.lib // (lib' final))
