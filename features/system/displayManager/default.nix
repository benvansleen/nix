{
  flake.modules.nixos.displayManager =
    { pkgs, ... }:
    {
      config = {
        services = {
          displayManager.sddm = {
            enable = true;
            extraPackages = with pkgs; [ qt6.qtmultimedia ];
            wayland.enable = true;
            theme = "${import ./_sddm-theme.nix {
              inherit pkgs;
              image = ./sddm-background.png;
            }}";
          };
        };
      };
    };
}
