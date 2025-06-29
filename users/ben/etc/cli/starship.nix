{
  config,
  lib,
  osConfig,
  ...
}:

let
  inherit (osConfig.users.users.${config.home.username}) shell;
in
{
  config.programs.starship.settings = {
    add_newline = false;
    character = {
      success_symbol = if shell.pname != "nushell" then "" else "";
      error_symbol = if shell.pname != "nushell" then "(bold red)" else "";
      vicmd_symbol = if shell.pname != "nushell" then " " else "";
    };
    # custom = {
    #   direnv = {
    #     format = "[\\[direnv\\]]($style) ";
    #     style = "fg:yellow dimmed";
    #     when = "printenv DIRENV_FILE";
    #   };
    # };
    fill = {
      disabled = false;
      symbol = " ";
    };
    direnv = {
      disabled = false;
      allowed_msg = "󰄬";
      not_allowed_msg = " ";
      loaded_msg = "󰄬";
      unloaded_msg = " ";
      format = ''[\[$symbol$loaded󰿟$allowed\]]($style) '';
      style = "dimmed yellow";
    };
    hostname = {
      ssh_only = true;
      ssh_symbol = " ";
      format = "[$ssh_symbol$hostname |]($style) ";
      style = "green";
    };
    git_metrics = {
      disabled = false;
    };
    memory_usage = {
      disabled = false;
      symbol = "󰍛 ";
      format = "[\[$symbol \${ram}( \| \${swap})\]]($style) ";
    };
    nix_shell = {
      disabled = false;
      heuristic = false;
      symbol = if config.modules.cli.ghostty.enable then "" else "❄️ ";
      format = ''[\[($symbol)nix shell\]]($style) '';
      style = "dimmed blue";
    };
    format = lib.concatStrings [
      # "$username"
      "$hostname"
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
      "$conda"
      "$spack"
      "$memory_usage"
      "$aws"
      "$gcloud"
      "$openstack"
      "$azure"
      "$crystal"
      "$sudo"
      "$cmd_duration"
      "$jobs"
      "$battery"
      "$time"
      "$status"
      # "$fill"
      "$shell"
      # "$nix_shell"
      # "$direnv"
      "$line_break"
      "$character"
    ];
    right_format = lib.concatStrings [
      # "\${custom.direnv}"
      "$nix_shell"
      "$direnv"
    ];
    scan_timeout = 10;

  };
}
