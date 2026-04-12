_: {
  flake.modules.homeManager.ollamaCopilot = {
    imports = [ ../../modules/home/ollama-copilot.nix ];

    config.modules.ollama-copilot.enable = true;
  };
}
