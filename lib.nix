lib: overlays:
{ nixpkgs, systems, ... }@inputs:

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

  mkPkgs = cfg: import nixpkgs cfg;
in
{
  importAll = dir: { imports = nixFilesInDir dir; };

  mkSystem =
    system: extraModules:
    (
      let
        pkgs-config = { inherit system overlays; };
        pkgs = mkPkgs pkgs-config;
        pkgs-unfree = mkPkgs (
          pkgs-config
          // {
            config.allowUnfree = true;
          }
        );
      in
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit pkgs pkgs-unfree;
        } // inputs;
        modules = [
          ./modules/system
          ./hosts
          ./users

          {
            environment.etc.nixos.source = ./.;
          }
        ] ++ extraModules;
      }
    );

  mkUser =
    {
      enable,
      user,
      extraHomeModules,
      extraConfig,
    }:
    let
      allHomeModules =
        with lib;
        pipe inputs [
          (filterAttrs (_moduleName: module: module ? homeManagerModules))
          (mapAttrsToList (
            moduleName:
            { homeManagerModules, ... }:
            homeManagerModules.default or homeManagerModules.${moduleName}
              or homeManagerModules.${head (attrNames homeManagerModules)}
          ))
        ];
    in
    extraConfig
    // {
      home-manager = enable {
        users.${user} = _: {
          imports = allHomeModules ++ [ ./modules/home ] ++ extraHomeModules;
        };
      };
    };

  eachSystem =
    f:
    nixpkgs.lib.genAttrs (import systems) (
      system:
      f {
        inherit system;
        pkgs = nixpkgs.legacyPackages.${system};
      }
    );
}
