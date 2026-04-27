{ inputs, ... }:

{
  flake.modules.nixos.nix =
    { config, ... }:
    {
      config = {
        nixpkgs.flake = {
          setNixPath = true;
          setFlakeRegistry = true;
        };
        nix = {
          buildMachines = builtins.filter (m: m.hostName != config.machine.name) [
            {
              hostName = "desktop";
              sshUser = "remotebuild";
              protocol = "ssh-ng";
              systems = [
                "x86_64-linux"
                "aarch64-linux"
              ];
              speedFactor = 10;
              maxJobs = 32;
              supportedFeatures = [
                "nixos-test"
                "big-parallel"
                "kvm"
              ];
            }
          ];
          channel.enable = false;
          distributedBuilds = true;
          gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 30d";
          };
          registry.nixpkgs.flake = inputs.nixpkgs;
          settings = {
            accept-flake-config = true;
            auto-optimise-store = true;
            builders-use-substitutes = true;
            cores = 0;
            connect-timeout = 5;
            download-buffer-size = 524288000;
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            fallback = true;
            min-free = 128000000; # 128 MB
            trusted-users = [ "@wheel" ];
            use-xdg-base-directories = true;
            warn-dirty = false;
          };
        };
      };
    };
}
