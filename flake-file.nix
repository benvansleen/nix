{ inputs, ... }:
{
  imports = [
    (inputs.import-tree ./modules)
    (inputs.import-tree ./overlays)
  ];
}
