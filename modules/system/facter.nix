{ inputs, ... }:

{
  flake-file.inputs = {
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  flake.modules.nixos.facter =
    { config, ... }:
    {
      imports = [
        inputs.nixos-facter-modules.nixosModules.facter
      ];

      config = {
        facter.report = inputs.secrets.hardware."${config.machine.name}-facter.json";
      };
    };
}
