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
          rev = "8a63cfbf2581ed35c7c771bcaa5516678238acc3";
          hash = "sha256-UyllLHdyzZf/Fxp2oW2MDw0o28FruJBNiRZv7LL/mAo=";
        };
        patches = [ ];
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
