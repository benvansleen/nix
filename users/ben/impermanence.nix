{ lib, ... }@inputs:

let
  inherit (inputs.lib) mkIf;
  inherit (inputs.config.modules.system) impermanence;
  inherit (inputs.home-dir) root config data;

  persistFiles = [
    "${data}/zsh/history"
    ".ssh/known_hosts"
  ];
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
    files = persistFiles;
  };

  home.activation."rm-persisted-files" = mkIf impermanence.enable (
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      for f in ${toString persistFiles}; do
        echo "Removing $f"
        rm $f
      done
    ''
  );
}
