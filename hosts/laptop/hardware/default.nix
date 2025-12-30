{
  nixos-hardware,
  pkgs,
  ...
}:

{
  imports = with nixos-hardware.nixosModules; [
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
      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          # Energy Performance Preference (EPP)
          # This is supported by i7-8565U
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          # Optional: Help laptop stay cool and quiet on battery
          CPU_BOOST_ON_BAT = 0;
        };
      };
    };
  };
}
