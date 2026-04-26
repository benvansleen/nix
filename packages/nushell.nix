{
  pkgs,
  fetchFromGitHub,
  rustPlatform,
  ...
}:

pkgs.nushell.overrideAttrs (old: rec {
  src = fetchFromGitHub {
    owner = "benvansleen";
    repo = old.pname;
    rev = "test/keychords-and-skim";
    hash = "sha256-0HYczT0iA1r8VIt8HJ4hw6McM3m9wVSbDZvKt0P5+m4=";
  };
  cargoBuildFeatures = [ "skim" ];
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-teoexaaYib4JbYaxE4NRrffLLO1DqjQPv02tRiqtt0s=";
  };
})
