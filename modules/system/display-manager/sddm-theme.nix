{ pkgs, image, ... }:

pkgs.stdenv.mkDerivation {
  name = "sddm-theme";
  src = pkgs.fetchFromGitHub {
    owner = "MarianArlt";
    repo = "sddm-sugar-dark";
    rev = "ceb2c455663429be03ba62d9f898c571650ef7fe";
    sha256 = "sha256-flOspjpYezPvGZ6b4R/Mr18N7N3JdytCSwwu6mf4owQ=";
  };
  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
    rm $out/Background.jpg
    cp ${image} $out/Background.jpg
  '';
}
