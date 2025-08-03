{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.ollama-copilot;
in
{
  options.modules.ollama-copilot = {
    enable = mkEnableOption "Ollama Copilot";
    port = mkOption {
      type = types.port;
      default = 11437;
      description = "port ollama-copilot listens on";
    };
    model = mkOption {
      type = types.str;
      default = "codellama:code";
      description = "model to use";
    };
    num-tokens = mkOption {
      type = types.int;
      default = 50;
      description = "number of tokens per inference";
    };
    system = mkOption {
      type = types.str;
      default = "";
      description = "system prompt for the llm";
    };
  };

  config = mkIf cfg.enable {
    modules.impermanence.persistedDirectories = [
      config.services.ollama.environmentVariables.OLLAMA_MODELS
    ];

    services.ollama = {
      enable = !builtins.isNull osConfig.machine.acceleration;
      environmentVariables = {
        OLLAMA_MODELS = ".local/share/ollama";
      };
    };

    systemd.user.services.ollama-copilot = mkIf config.services.ollama.enable {
      Unit = {
        Description = "proxy service to run copilot through ollama";
        After = [ "ollama.service" ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        ExecStart = pkgs.writeShellScript "start-ollama-copilot" ''
          ${lib.getExe pkgs.ollama-copilot} \
            -port ":${toString cfg.port}" \
            -model "${cfg.model}" \
            -num-predict ${toString cfg.num-tokens} \
            -system "${cfg.system}"
        '';
      };
    };
  };
}
