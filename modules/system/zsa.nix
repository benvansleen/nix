{
  flake.modules.nixos.zsa =
    {
      pkgs,
      ...
    }:
    {
      config = {
        hardware.keyboard.zsa.enable = true;
        environment.systemPackages = with pkgs; [ keymapp ];
      };
    };
}
