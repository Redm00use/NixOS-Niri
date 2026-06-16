{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  cargo-tauri,
  nodejs,
  webkitgtk_4_1,
  gtk3,
  glib,
  libsoup_3,
  cairo,
  gdk-pixbuf,
  librsvg,
  libayatana-appindicator,
  alsa-lib,
  ffmpeg,
  yt-dlp,
}:

rustPlatform.buildRustPackage rec {
  pname = "sunder";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "FrogSnot";
    repo = "Sunder";
    rev = "v${version}";
    hash = "sha256-PZs2GQtKtG57gZLDybHh1fkNJRmI6HeMmPWFWt+0H/Y=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    nodejs
    pkg-config
    cargo-tauri
    makeWrapper
  ];

  buildInputs = [
    webkitgtk_4_1
    gtk3
    glib
    libsoup_3
    cairo
    gdk-pixbuf
    librsvg
    libayatana-appindicator
    alsa-lib
  ];

  cargoRoot = "src-tauri";
  npmRoot = ".";

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    npm ci
    npm run build
    cargo tauri build --no-bundle
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/applications $out/share/pixmaps
    install -Dm755 src-tauri/target/release/sunder $out/bin/sunder
    wrapProgram $out/bin/sunder \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg yt-dlp ]}

    install -Dm644 sunder.desktop $out/share/applications/Sunder.desktop
    install -Dm644 src-tauri/icons/128x128.png $out/share/pixmaps/sunder.png

    substituteInPlace $out/share/applications/Sunder.desktop \
      --replace-fail 'Exec=sunder' 'Exec=env -u DISPLAY sunder'

    runHook postInstall
  '';

  meta = {
    description = "Desktop YouTube music client";
    homepage = "https://github.com/FrogSnot/Sunder";
    license = lib.licenses.agpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sunder";
  };
}
