{ inputs, ... }:
{
  flake-file.inputs.nixos-cli = {
    url = "github:nix-community/nixos-cli";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-compat.follows = "flake-compat";
      optnix.inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
  };

  flake.modules.nixos.nixosCli = {
    imports = [ inputs.nixos-cli.nixosModules.nixos-cli ];

    config = {
      services.nixos-cli = {
        enable = true;
        prebuildOptionCache = false;
        useActivationInterface = true;
        config = {
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
            root_command = inputs.self.constants.privilege-escalation;
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
