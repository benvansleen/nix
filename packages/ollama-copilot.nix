{
  lib,
  buildGoModule,
  fetchFromGitHub,
  ...
}:

buildGoModule rec {
  pname = "ollama-copilot";
  version = "master";
  src = fetchFromGitHub {
    owner = "benvansleen";
    repo = pname;
    rev = "master";
    hash = "sha256-Qg/hx9/iEm4aYTalcwkPgFDMeDxe5M5fvzdqCldXr88=";
  };

  vendorHash = "sha256-g27MqS3qk67sve/jexd07zZVLR+aZOslXrXKjk9BWtk=";

  meta = {
    mainProgram = pname;
    description = "Proxy that allows you to use ollama as a copilot like Github copilot";
    homepage = "https://github.com/bernardo-bruning/ollama-copilot";
    license = lib.licenses.mit;
  };
}
