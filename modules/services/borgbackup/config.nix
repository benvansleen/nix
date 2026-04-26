{
  flake.borgbackup-machine-config = {
    clients = {
      desktop = {
        paths = [ "/persist" ];
        exclude = [
          "sh:**/llama/models/**"
          "sh:**/llama/llama-models/**"
          "sh:**/ollama/blobs/**"

          "sh:**/node_modules/**"
          "sh:**/.venv/**"
          "sh:**/target/debug/**"
          "sh:**/target/release/**"
        ];
      };
      laptop = {
        paths = [ "/persist" ];
        exclude = [ ];
      };
      pi = {
        paths = [ "/" ];
        exclude = [
          "/bin"
          "/boot"
          "/dev"
          "/lib"
          "/mnt"
          "/nix"
          "/proc"
          "/run"
          "/sys"
          "/usr"
        ];
      };
    };
  };
}
