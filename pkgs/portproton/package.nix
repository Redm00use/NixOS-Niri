{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeDesktopItem,
  copyDesktopItems,
  makeWrapper,
  bash,
  cabextract,
  coreutils,
  curl,
  file,
  findutils,
  gawk,
  gnugrep,
  gnutar,
  gnused,
  gzip,
  icoutils,
  jq,
  lsof,
  pciutils,
  procps,
  python3,
  steam-run,
  systemd,
  xdg-utils,
  unzip,
  usbutils,
  utillinux,
  wget,
  which,
  xz,
  yad,
  zenity,
  zstd,
}:

let
  version = "1.7.5";
  pname = "portproton";

  src = fetchFromGitHub {
    owner = "Castro-Fidel";
    repo = "PortProton_ALT";
    rev = "v${version}";
    hash = "sha256-JFBhrN9EKpgLOYGdSOlswBUzFKXbzeiXkeuxnDQJPKw=";
  };

  desktopItem = makeDesktopItem {
    name = "ru.linux_gaming.PortProton";
    exec = "portproton";
    icon = "ru.linux_gaming.PortProton";
    desktopName = "PortProton";
    genericName = "Wine/Proton Prefix Manager";
    comment = "Convenient graphical interface for managing Wine/Proton prefixes";
    categories = [ "Game" "Utility" ];
    terminal = false;
    type = "Application";
  };

  runtimePath = lib.makeBinPath [
    bash
    cabextract
    coreutils
    curl
    file
    findutils
    gawk
    gnugrep
    gnused
    gnutar
    gzip
    icoutils
    jq
    lsof
    pciutils
    procps
    python3
    systemd
    xdg-utils
    unzip
    usbutils
    utillinux
    wget
    which
    xz
    yad
    zenity
    zstd
  ];

in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    copyDesktopItems
    makeWrapper
  ];

  patchPhase = ''
    # PortProton checks if script_path == "/usr/bin" to determine
    # if it's already installed. On NixOS it runs from the Nix store,
    # so this check always fails and it re-installs on every launch.
    # Fix: use config file existence instead of script location.
    substituteInPlace portproton \
      --replace-fail 'if [[ "$script_path" == "/usr/bin" ]] \' 'if [[ -f "''${PP_CONFIG_FILE}" ]] \'

    # Preserve downloaded Wine/Proton builds (dist/) between launches
    substituteInPlace portproton \
      --replace-fail 'rm -fr "''${PORT_WINE_DATA_PATH}/dist/"' 'echo "Preserving dist/ (NixOS patch)"'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/scalable/apps
    mkdir -p $out/share/metainfo
    mkdir -p $out/share/licenses/${pname}

    # Install main script
    install -Dm755 portproton $out/bin/.portproton-unwrapped

    # Install desktop extras
    install -Dm644 ru.linux_gaming.PortProton.svg \
      $out/share/icons/hicolor/scalable/apps/ru.linux_gaming.PortProton.svg
    install -Dm644 ru.linux_gaming.PortProton.metainfo.xml \
      $out/share/metainfo/ru.linux_gaming.PortProton.metainfo.xml
    install -Dm644 LICENSE \
      $out/share/licenses/${pname}/LICENSE

    # Wrap the script with PATH to all runtime deps
    wrapProgram $out/bin/.portproton-unwrapped \
      --prefix PATH : ${runtimePath}

    # Create the launcher wrapper via steam-run for FHS compatibility
    # PortProton downloads dynamically-linked binaries (yad_gui_pp, python3.9, etc.)
    # that require an FHS environment to work on NixOS.
    makeWrapper ${steam-run}/bin/steam-run $out/bin/portproton \
      --add-flags $out/bin/.portproton-unwrapped

    runHook postInstall
  '';

  desktopItems = [ desktopItem ];

  meta = with lib; {
    description = "Wine/Proton game launcher and prefix manager";
    longDescription = ''
      PortProton is a convenient graphical interface for managing Wine/Proton
      prefixes and installing/running Windows games and applications on Linux.
      It supports various Wine builds and Proton versions.
    '';
    homepage = "https://github.com/Castro-Fidel/PortProton_ALT";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
    mainProgram = "portproton";
  };
}
