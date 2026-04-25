{
  flake.modules.homeManager.opencode =
    { lib, ... }:
    {
      config = {
        programs.opencode = {
          enable = true;
          settings = {
            autoupdate = false;
            theme = lib.mkForce "gruvbox"; # override stylix theme
          };
        };
        persist.directories = [
          "@config@/opencode"
          "@state@/opencode"
          "@data@/opencode"
          "@cache@/opencode"
        ];
      };
    };
}
