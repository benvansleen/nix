{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.emacs;

  init-el =
    config.programs.emacs.extraConfig
    + ''
      (defvar my/dashboard-img "${cfg.dashboard-img}")
    ''
    + lib.optionalString cfg.framesOnlyMode ''
      (use-package frames-only-mode
        :config
        (dolist (f '(embark-act
                     vterm-toggle
                     org-latex-export-to-pdf
                     org-fragtog--post-cmd
                     geiser-debug-debugger-quit
                     git-gutter:revert-hunk
                     git-gutter:stage-hunk
                     corfu-doc-toggle))
          (add-to-list 'frames-only-mode-use-window-functions f))
        :init
        (frames-only-mode))
    ''
    + (builtins.readFile cfg.init-el);

  emacs-pkg = pkgs.emacs-unstable-pgtk;
  emacs = pkgs.emacsWithPackagesFromUsePackage {
    package = lib.optimizeForThisHostIfPowerful {
      config = osConfig;
      pkg = emacs-pkg;
      extraFlags = [
        "-pipe"
        "-fomit-frame-pointer"
      ];
    };
    config = init-el;
    defaultInitFile = true;
    alwaysEnsure = true;
    alwaysTangle = true;
    extraEmacsPackages =
      epkgs:
      with epkgs;
      (
        [
          treesit-grammars.with-all-grammars
        ]
        ++ (config.programs.emacs.extraPackages epkgs)
      );
  };
in
{

  options.modules.emacs = {
    enable = mkEnableOption "emacs";
    init-el = mkOption {
      type = types.path;
      description = "emacs init.el configuration";
    };
    framesOnlyMode = mkEnableOption "emacs with frames-only-mode";
    dashboard-img = mkOption {
      type = types.path;
      description = "Path to the image to display in the dashboard";
    };
  };

  config = mkIf cfg.enable {
    programs.emacs = {
      enable = true;
      package = emacs;
    };

    services.emacs = {
      enable = true;
      package = emacs;
      defaultEditor = true;
      socketActivation.enable = true;
      client.enable = true;
    };

  };
}
