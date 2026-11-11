{ pkgs ? import <nixpkgs> { }, forceXwayland ? false, forceSoftwareRendering ? false }:

let
  lib = pkgs.lib;

  qtPlatformArgs = lib.optionalString forceXwayland "--set QT_QPA_PLATFORM xcb";

  softwareRenderArgs = lib.optionalString forceSoftwareRendering
    "--set QML_SCENE_GRAPH software --set LIBGL_ALWAYS_SOFTWARE 1";

  runtimeDeps = with pkgs; [
    coreutils
    lsb-release
    net-tools
    iproute2
    iptables
    procps
  ];

  # Without this, Happ's bundled libxkbcommon finds no XKB data under
  # XWayland/xcb and segfaults on the first keypress (NULL xkb_state).
  xkbConfigRoot = "${pkgs.xkeyboard_config}/share/X11/xkb";
in
pkgs.stdenv.mkDerivation rec {
  pname = "happ-desktop";
  version = "4.2.1";

  src = pkgs.fetchurl {
    url = "https://github.com/Happ-proxy/happ-desktop/releases/download/${version}/Happ.linux.x64.deb";
    sha256 = "vIvAvWH4/ZblxYEXzthc2wrcPCinA+eWXs3/EIlUrnU=";
  };

  nativeBuildInputs = with pkgs; [
    dpkg
    autoPatchelfHook
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  dontWrapQtApps = true;

  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    libGL
    libX11
    libSM
    libICE
    libXext
    libXi
    libXtst
    e2fsprogs
    fontconfig
    freetype
    libgpg-error
    qt6.qtwayland
    openssl
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/happ $out/share/applications $out/bin

    dpkg -x $src .
    cp -r opt/happ/* $out/happ/

    if [ -d "usr/share" ]; then
      cp -r usr/share/* $out/share/
    fi

    ${lib.optionalString forceXwayland ''
      rm -rf $out/happ/lib/plugins/wayland-*
      rm -f $out/happ/lib/plugins/platforms/libqwayland-*.so
    ''}

    for exe in Happ happd; do
      wrapProgram $out/happ/bin/$exe \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.openssl ]}" \
        --prefix PATH : "${lib.makeBinPath runtimeDeps}" \
        --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
        --set XKB_CONFIG_ROOT "${xkbConfigRoot}" \
        ${qtPlatformArgs} \
        ${softwareRenderArgs}
    done

    ln -s $out/happ/bin/Happ $out/bin/happ

    runHook postInstall
  '';

  meta = {
    description = "Happ proxy desktop client (VLESS/VMess/Trojan/Shadowsocks) with a TUN daemon";
    homepage = "https://github.com/Happ-proxy/happ-desktop";
    platforms = [ "x86_64-linux" ];
    mainProgram = "happ";
    # license intentionally unset: closed-source redistributable, kept out of
    # allowUnfree's path for users who don't already enable it.
  };
}
