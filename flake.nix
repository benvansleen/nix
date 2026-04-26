# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    allfollow.url = "github:spikespaz/allfollow";
    centerpiece.url = "github:friedow/centerpiece";
    clonix.url = "github:benvansleen/clonix";
    disko.url = "github:nix-community/disko";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    extra-container.url = "github:erikarvstedt/extra-container";
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager.url = "github:nix-community/home-manager";
    hyprbar.url = "github:benvansleen/hyprbar";
    impermanence.url = "github:nix-community/impermanence";
    import-tree.url = "github:vic/import-tree";
    lanzaboote.url = "github:nix-community/lanzaboote";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixos-cli.url = "github:nix-community/nixos-cli";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nvim.url = "github:benvansleen/nvim/migrate-to-nix-wrapper-modules";
    opencode.url = "github:anomalyco/opencode";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    secrets.url = "git+ssh://git@github.com/benvansleen/secrets.git";
    sops-nix.url = "github:Mic92/sops-nix";
    stylix.url = "github:nix-community/stylix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
}
