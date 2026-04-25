{ inputs, ... }:

{
  flake.modules.homeManager.ben-emacs =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        emacs
      ];

      config = {
        home.packages = with pkgs; [
          delta # required for `magit-delta`
        ];

        persist.directories = [ "@config@/emacs/var" ];

        modules.emacs = {
          init-el = ./init.el;
          framesOnlyMode = true;
          dashboard-img = ./floating-gnu-flute.png;
        };
      };
    };
}
