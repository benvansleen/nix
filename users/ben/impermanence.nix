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
      {
        directory = "Code";
        method = "symlink";
      }
      {
        directory = "Documents";
        method = "symlink";
      }
      {
        directory = "Downloads";
        method = "symlink";
      }
      {
        directory = "Pictures";
        method = "symlink";
      }
      {
        directory = "${data}/atuin";
        method = "symlink";
      }
    ];
    files = [
      "${data}/zsh/history"
    ];
  };
}
