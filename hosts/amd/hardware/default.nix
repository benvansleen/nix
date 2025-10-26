{ pkgs, ... }:

{
  config = {
    hardware = {
      ## TODO: add amd ryzen-specific support (eg for zen temp monitoring)

      amdgpu = {
        initrd.enable = true;
        opencl.enable = true;
      };
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          vulkan-headers
          vulkan-loader
          vulkan-validation-layers
          vulkan-extension-layer
        ];

      };
    };

    nixpkgs.config.rocmSupport = true;

    # Need to pull later checkout than latest release (0.9) for MSI
    # board support. To configure Thermalright fans, need to set
    # resizable addressable RGB zones to 8
    # https://www.reddit.com/r/OpenRGB/comments/1idmmke/thermalright_fan_rgb_not_changing/
    services.hardware.openrgb = {
      # Need to allow ~1min after systemd service starts before
      # it can handle requests
      enable = true;
      package = pkgs.openrgb.overrideAttrs (_prev: {
        version = "experimental";
        src = pkgs.fetchFromGitLab {
          owner = "CalcProgrammer1";
          repo = "OpenRGB";
          rev = "58c609674db9abb87c927873db7ae9f12758e322";
          hash = "sha256-8QV1BhLLEThKIJTe3syxmzGaX/8jbYqCw1P4AcB/IbA=";
        };
        postPatch = ''
          patchShebangs scripts/build-udev-rules.sh
          substituteInPlace scripts/build-udev-rules.sh \
            --replace /usr/bin/env "${pkgs.coreutils}/bin/env"
        '';
      });
    };
    modules.impermanence.persistedDirectories = [
      "/var/lib/OpenRGB"
    ];
  };
}
