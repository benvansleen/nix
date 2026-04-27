{ self, ... }:

{
  flake.modules.nixos.users = {
    imports = with self.modules.nixos; [
      homeManager

      ben
    ];
  };
}
