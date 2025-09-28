{ pkgs, image, ... }:

pkgs.stdenv.mkDerivation {
  name = "astronaut-theme";
  src = pkgs.fetchFromGitHub {
    owner = "Keyitdev";
    repo = "sddm-astronaut-theme";
    rev = "c10bd950544036c7418e0f34cbf1b597dae2b72f"; # Aug 30, 2025
    sha256 = "sha256-ITufiMTnSX9cg83mlmuufNXxG1dp9OKG90VBZdDeMxw=";
  };
  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
    rm $out/Backgrounds/astronaut.png
    cp ${image} $out/Backgrounds/astronaut.png
    sed -i 's|HourFormat=".*"|HourFormat="\n\n\nh:mm ap"|' $out/Themes/astronaut.conf
    sed -i 's|DateFormat=".*"|DateFormat="dddd, MMMM d"|' $out/Themes/astronaut.conf
    sed -i 's|FormPosition=".*"|FormPosition="left"|' $out/Themes/astronaut.conf
    sed -i 's|HaveFormBackground=".*"|HaveFormBackground="true"|' $out/Themes/astronaut.conf
    sed -i 's|root.font.pointSize \* 9|root.font.pointSize \* 3|' $out/Components/Clock.qml
  '';
}
