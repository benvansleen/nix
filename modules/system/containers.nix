{ inputs, ... }:

{
  flake-file.inputs.extra-container = {
    url = "github:erikarvstedt/extra-container";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.inputs.systems.follows = "systems";
    };
  };

  flake.modules.nixos.containers =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ inputs.extra-container.nixosModules.default ];

      options.modules.containers = with lib; {
        disable-podman-dns = mkEnableOption "disable DNS in podman";
      };

      config =
        let
          cfg = config.modules.containers;
        in
        {
          programs.extra-container.enable = true;
          virtualisation = {
            oci-containers.backend = "podman";
            podman = {
              enable = true;
              dockerCompat = true;
              defaultNetwork.settings.dns_enabled = !cfg.disable-podman-dns;
              autoPrune = {
                enable = true;
                dates = "weekly";
              };
            };
            containers.storage.settings = {
              storage = {
                driver = "overlay";
                graphroot = "/var/lib/containers/storage";
                runroot = "/run/containers/storage";
              };
            };
          };

          environment.systemPackages = with pkgs; [
            nixos-container
            podman-compose
            podman-tui
            dive
          ];

          persist.directories = [
            config.virtualisation.containers.storage.settings.storage.graphroot
          ];
        };
    };

  flake.modules.homeManager.containers =
    { config, ... }:
    {
      services.podman.enable = true;
      persist.directories = with config.xdg; [
        "${dataHome}/containers"
        "${cacheHome}/containers"
      ];
    };
}
