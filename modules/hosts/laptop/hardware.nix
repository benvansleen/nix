{ inputs, ... }:

{
  flake-file.inputs = {
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  flake.modules.nixos.laptop-hardware =
    { pkgs, ... }:
    {
      imports = with inputs.nixos-hardware.nixosModules; [
        common-pc
        common-pc-ssd
      ];

      config = {
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver # Better for Broadwell+ (including your 8th gen)
            libva-vdpau-driver
            libvdpau-va-gl
          ];
        };
        powerManagement.powertop.enable = true;
        services = {
          thermald.enable = true;

          ## disable default power management in favor of `auto-cpufreq`
          power-profiles-daemon.enable = false;
          auto-cpufreq = {
            enable = true;
            settings = {
              battery = {
                governor = "powersave";
                turbo = "never";
                energy_performance_preference = "power";
                energy_perf_bias = "power";
              };
              charger = {
                governor = "performance";
                turbo = "auto";
                energy_performance_preference = "performance";
                energy_perf_bias = "performance";
              };
            };
          };
        };
      };

    };
}
