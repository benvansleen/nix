{ lib, ... }:

{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "";
        error_symbol = "(bold red)";
        vicmd_symbol = " ";
      };
      format = lib.concatStrings [
        # "$username"
        # "$hostname"
        "$localip"
        "$shlvl"
        "$singularity"
        "$kubernetes"
        "$directory"
        "$vcsh"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$hg_branch"
        "$docker_context"
        "$package"
        "$buf"
        "$c"
        "$cmake"
        "$cobol"
        "$container"
        "$daml"
        "$dart"
        "$deno"
        "$dotnet"
        "$elixir"
        "$elm"
        "$erlang"
        "$golang"
        "$haskell"
        "$helm"
        "$java"
        "$julia"
        "$kotlin"
        "$lua"
        "$nim"
        "$nodejs"
        "$ocaml"
        "$perl"
        "$php"
        "$pulumi"
        "$purescript"
        "$python"
        "$rlang"
        "$red"
        "$ruby"
        "$rust"
        "$scala"
        "$swift"
        "$terraform"
        "$vlang"
        "$vagrant"
        "$zig"
        "$nix_shell"
        "$conda"
        "$spack"
        "$memory_usage"
        "$aws"
        "$gcloud"
        "$openstack"
        "$azure"
        "$crystal"
        "$custom"
        "$sudo"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$battery"
        "$time"
        "$status"
        "$shell"
        "$character"
      ];
      scan_timeout = 10;

    };
  };
}
