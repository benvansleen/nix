{ inputs, ... }:
{
  imports = [
    (inputs.import-tree ./modules)
    ((inputs.import-tree.match ".*/flake-module\\.nix") ./hosts)
  ];
}
