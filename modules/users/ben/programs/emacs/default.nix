{ self, ... }:

{
  flake.modules.homeManager.ben-emacs =
    { config, pkgs, ... }:
    {
      imports = with self.modules.homeManager; [
        emacs
      ];

      config = {
        home.packages = with pkgs; [
          delta # required for `magit-delta`
        ];

        persist.directories = [ "${config.xdg.configHome}/emacs/var" ];

        modules.emacs = {
          init-el = ./init.el;
          framesOnlyMode = true;
          dashboard-img = ./floating-gnu-flute.png;
        };
      };
    };
}
