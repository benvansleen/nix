{ inputs, ... }:
{
  imports = [
    (inputs.import-tree ./features)
    ((inputs.import-tree.match ".*/flake-module\\.nix") ./hosts)
  ];
}
