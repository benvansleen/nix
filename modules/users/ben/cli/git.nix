{ moduleWithSystem, self, ... }:

{
  flake.modules.homeManager.ben-git = moduleWithSystem (
    { system, ... }:
    {
      imports = with self.modules.homeManager; [
        gh
        git
      ];

      config = {
        home.packages = [
          self.packages.${system}.ghui
        ];
      };
    }
  );
}
