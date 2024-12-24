inputs:

let
  inherit (inputs.lib) mkIf;
  inherit (inputs.config.modules.system) impermanence;
  inherit (inputs.home-dir) root config data;
in
{
  home.persistence."${impermanence.persistRoot}${root}" = mkIf impermanence.enable {
    allowOther = true;
    directories = [
      "${config}/nix"
      "${config}/emacs/var"
      "Code"
      "Documents"
      "Downloads"
      "Pictures"
      "${data}/atuin"
    ];
    files = [
      "${data}/zsh/history"
    ];
  };
}
