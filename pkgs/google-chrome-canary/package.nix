{
  fetchurl,
  lib,
  makeWrapper,
  patchelf,
  stdenvNoCC,
  bintools,

  # Linked dynamic libraries.
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gcc-unwrapped,
  gdk-pixbuf,
  glib,
  gtk3,
  gtk4,
  libdrm,
  libglvnd,
  libkrb5,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  libgbm,
  nspr,
  nss,
  pango,
  pipewire,
  vulkan-loader,
  wayland,

  # Command line programs
  coreutils,

  # command line arguments which are always set e.g "--disable-gpu"
  commandLineArgs ? "",

  # Will crash without.
  systemd,

  # Loaded at runtime.
  libexif,
  pciutils,

  # Additional dependencies according to other distros.
  ## Ubuntu
  curl,
  liberation_ttf,
  util-linux,
  wget,
  xdg-utils,
  ## Arch Linux.
  flac,
  harfbuzz,
  icu,
  libopus,
  libpng,
  snappy,
  speechd-minimal,
  ## Gentoo
  bzip2,
  libcap,

  # Fonts (See issue #463615)
  makeFontsConf,
  noto-fonts-cjk-sans,
  noto-fonts-cjk-serif,

  # Necessary for USB audio devices.
  libpulseaudio,
  pulseSupport ? true,

  adwaita-icon-theme,
  gsettings-desktop-schemas,

  # For video acceleration via VA-API (--enable-features=VaapiVideoDecoder)
  libva,
  libvaSupport ? true,

  # For Vulkan support (--enable-features=Vulkan)
  addDriverRunpath,

  # Enables Chrome's "Use QT" appearance to introspect the user's Plasma theme
  plasmaSupport ? false,
  qt6,
  kdePackages,

  # Create a symlink at $out/bin/google-chrome
  withSymlink ? true,
}:

let
  pname = "google-chrome-canary";
  appname = "chrome-canary";
  dist = "canary";
  version = "151.0.7892.0";

  opusWithCustomModes = libopus.override { withCustomModes = true; };

  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    bzip2
    cairo
    coreutils
    cups
    curl
    dbus
    expat
    flac
    fontconfig
    freetype
    gcc-unwrapped.lib
    gdk-pixbuf
    glib
    harfbuzz
    icu
    libcap
    libdrm
    liberation_ttf
    libexif
    libglvnd
    libkrb5
    libpng
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
    libgbm
    nspr
    nss
    opusWithCustomModes
    pango
    pciutils
    pipewire
    snappy
    speechd-minimal
    systemd
    util-linux
    vulkan-loader
    wayland
    wget
  ]
  ++ lib.optional pulseSupport libpulseaudio
  ++ lib.optional libvaSupport libva
  ++ [
    gtk3
    gtk4
  ]
  ++ lib.optionals plasmaSupport [
    qt6.qtbase
    qt6.qtwayland
    kdePackages.plasma-integration
    kdePackages.breeze
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
  binpath = lib.makeBinPath deps;

  fontsConf = makeFontsConf {
    fontDirectories = [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];
  };

in
stdenvNoCC.mkDerivation {
  inherit pname version;
  inherit rpath binpath;

  src = fetchurl {
    url = "https://dl.google.com/linux/chrome/deb/pool/main/g/${pname}/${pname}_${version}-1_amd64.deb";
    hash = "sha256-36tqoRK1BjaZwScR8X7d4bltHP+2cktpMNg7M6/StdU=";
  };

  # With strictDeps on, some shebangs were not being patched correctly
  # ie, $out/share/google/chrome-canary/google-chrome-canary
  strictDeps = false;

  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  buildInputs = [
    # needed for XDG_ICON_DIRS
    adwaita-icon-theme
    glib
    gtk3
    gtk4
    # needed for GSETTINGS_SCHEMAS_PATH
    gsettings-desktop-schemas
  ];

  unpackPhase = ''
    runHook preUnpack
    ${lib.getExe' bintools "ar"} x $src
    tar xf data.tar.xz
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    exe=$out/bin/google-chrome-${dist}

    mkdir -p $out/bin $out/share
    cp -v -a opt/* $out/share
    cp -v -a usr/share/* $out/share

    # replace bundled vulkan-loader
    rm -v $out/share/google/${appname}/libvulkan.so.1
    ln -v -s -t "$out/share/google/${appname}" "${lib.getLib vulkan-loader}/lib/libvulkan.so.1"

    substituteInPlace $out/share/google/${appname}/google-${appname} \
      --replace-fail 'CHROME_WRAPPER' 'WRAPPER'
    substituteInPlace $out/share/applications/google-${appname}.desktop \
      --replace-fail /usr/bin/google-chrome-${dist} $exe
    substituteInPlace $out/share/gnome-control-center/default-apps/google-${appname}.xml \
      --replace-fail /opt/google/${appname}/google-${appname} $exe

    for icon_file in $out/share/google/chrome*/product_logo_[0-9]*.png; do
      num_and_suffix="''${icon_file##*logo_}"
      icon_size="''${num_and_suffix%_*}"
      logo_output_prefix="$out/share/icons/hicolor"
      logo_output_path="$logo_output_prefix/''${icon_size}x''${icon_size}/apps"
      mkdir -p "$logo_output_path"
      mv "$icon_file" "$logo_output_path/google-${appname}.png"
    done

    # "--simulate-outdated-no-au" disables auto updates and browser outdated popup
    makeWrapper "$out/share/google/${appname}/google-${appname}" "$exe" \
      ${lib.optionalString plasmaSupport ''
        --prefix QT_PLUGIN_PATH  : "${qt6.qtbase}/lib/qt-6/plugins" \
        --prefix QT_PLUGIN_PATH  : "${qt6.qtwayland}/lib/qt-6/plugins" \
        --prefix QT_PLUGIN_PATH  : "${kdePackages.plasma-integration}/lib/qt-6/plugins" \
        --prefix QT_PLUGIN_PATH  : "${kdePackages.breeze}/lib/qt-6/plugins" \
        --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "${qt6.qtwayland}/lib/qt-6/qml" \
      ''} \
      --prefix LD_LIBRARY_PATH : "$rpath" \
      --prefix PATH            : "$binpath" \
      --suffix PATH            : "${lib.makeBinPath [ xdg-utils ]}" \
      --prefix XDG_DATA_DIRS   : "$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH:${addDriverRunpath.driverLink}/share" \
      --set FONTCONFIG_FILE "${fontsConf}" \
      --set CHROME_WRAPPER  "google-chrome-${dist}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-wayland-ime=true --enable-features=WebRTCPipeWireCapturer}}" \
      --add-flags "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'" \
      --add-flags ${lib.escapeShellArg commandLineArgs}

    # Make sure that libGL and libvulkan are found by ANGLE libGLESv2.so
    for gl_lib in $out/share/google/${appname}/lib*GL*; do
      if [ -e "$gl_lib" ]; then
        patchelf --set-rpath $rpath "$gl_lib"
      fi
    done

    for elf in $out/share/google/${appname}/{chrome,chrome-sandbox,chrome_crashpad_handler}; do
      patchelf --set-rpath $rpath $elf
      patchelf --set-interpreter ${bintools.dynamicLinker} $elf
    done

    runHook postInstall
  '';

  postInstall = lib.optionalString withSymlink ''
    ln -s $out/bin/google-chrome-${dist} $out/bin/google-chrome
  '';

  meta = {
    description = "Freeware web browser developed by Google (Canary channel)";
    homepage = "https://www.google.com/chrome/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "google-chrome-${dist}";
  };
}
