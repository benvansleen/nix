{ inputs, ... }:

{
  flake.modules.nixos.users = {
    imports = with inputs.self.modules.nixos; [
      homeManager

      ben
    ];
  };
}
