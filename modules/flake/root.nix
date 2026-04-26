{ inputs, ... }:

{
  flake-file.inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-file.url = "github:vic/flake-file";
    import-tree.url = "github:vic/import-tree";
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.flake-file.flakeModules.allfollow
  ];
}
