_: {
  flake.modules.homeManager.ollamaCopilot =
    {
      config,
      osConfig,
      pkgs,
      lib,
      ...
    }:
    {
      options.modules.ollama-copilot = with lib; {
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

      config =
        let
          cfg = config.modules.ollama-copilot;
        in
        {
          persist.directories = [
            config.services.ollama.environmentVariables.OLLAMA_MODELS
          ];

          services.ollama = {
            enable = osConfig.machine.powerful;
            environmentVariables = {
              OLLAMA_MODELS = ".local/share/ollama";
            };
          };

          systemd.user.services.ollama-copilot = {
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
    };
}
