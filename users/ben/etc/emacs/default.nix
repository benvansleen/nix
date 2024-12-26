{ pkgs, ... }:

{
  home.packages = with pkgs; [
    delta # required for `magit-delta`
  ];
}
