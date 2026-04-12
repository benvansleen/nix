{
  flake.modules.nixos.fonts =
    {
      pkgs,
      ...
    }:
    {
      config = {
        fonts = {
          enableDefaultPackages = true;
          packages = with pkgs.nerd-fonts; [
            iosevka
            fira-code
            hack
            _3270
            victor-mono
          ];

          fontconfig = {
            defaultFonts = {
              serif = [ "Iosevka Etoile" ];
              sansSerif = [ "Iosevka Aile" ];
              monospace = [ "Hack" ];
            };
          };
        };
      };
    };
}
