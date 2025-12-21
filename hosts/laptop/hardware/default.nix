{
  nixos-hardware,
  ...
}:

{
  imports = with nixos-hardware.nixosModules; [
    common-pc
    common-pc-ssd
  ];
  config = { };
}
