{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      fira-code-nerdfont
      hack-font
    ];

    fontconfig = {
      defaultFonts = {
        serif = [ "Hack" ];
        sansSerif = [ "Fira Code" ];
        monospace = [ "Hack" ];
      };
    };
  };
}
