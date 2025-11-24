{
  stdenv,
  ...
}:
stdenv.mkDerivation {
  pname = "cursor-mouse";
  version = "1.0";

  src = ./src/Ellen-Joe;

  installPhase = ''
    mkdir -p $out/share/icons
    cp -r $src $out/share/icons/Cursor
  '';
}
