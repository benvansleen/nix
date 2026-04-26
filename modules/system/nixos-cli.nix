{ inputs, self, ... }:

{
  flake-file.inputs.nixos-cli = {
    url = "github:nix-community/nixos-cli";
    inputs = {
      flake-compat.follows = "flake-compat";
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.nixos.nixosCli = {
    imports = [ inputs.nixos-cli.nixosModules.nixos-cli ];

    config = {
      programs.nixos-cli = {
        enable = true;
        option-cache.enable = false;
        activation-interface.enable = true;
        settings = {
          aliases = {
            test = [
              "apply"
              "--no-boot"
            ];
            boot = [
              "apply"
              "--no-activate"
            ];
            switch = [ "apply" ];
            rollback = [
              "generation"
              "rollback"
            ];
          };
          general = {
            auto_rollback = true;
            color = true;
            root_command = self.constants.privilege-escalation;
            use_nvd = true;
          };
          apply = {
            ignore_dirty_tree = true;
            use_git_commit_msg = true;
            use_nom = true;
            reexec_as_root = true;
          };
        };
      };
    };
  };
}
