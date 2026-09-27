{ pkgs ? import <nixpkgs> { }, forceXwayland ? false, forceSoftwareRendering ? false }:

let
  lib = pkgs.lib;

  # Happ's bundled Qt6 Wayland plugins crash the client silently on
  # wlroots-based compositors (Hyprland, Sway, ...) -- ABI mismatch or
  # missing deps against what the vendor shipped. forceXwayland drops those
  # plugins from the package and pins the Qt platform to xcb (XWayland) so
  # Qt never tries to load them.
  qtPlatformArgs = lib.optionalString forceXwayland "--set QT_QPA_PLATFORM xcb";

  # Separate from forceXwayland: some GPU/driver combos render Happ's Qt
  # Quick UI incorrectly (or not at all) even under XWayland. This forces
  # software rendering as an independent escape hatch, since it addresses a
  # driver-level rendering issue rather than the Wayland plugin crash.
  softwareRenderArgs = lib.optionalString forceSoftwareRendering
    "--set QML_SCENE_GRAPH software --set LIBGL_ALWAYS_SOFTWARE 1";

  # External command-line tools that the Happ client and its helper scripts shell
  # out to at runtime. Wrapping them into Happ's PATH makes the client
  # self-contained instead of depending on whatever PATH the desktop session
  # happens to export:
  #   - uname (coreutils) / lsb_release  -> OS & device-info reporting
  #   - ifconfig / route (net-tools)     -> network interface discovery
  #   - ip (iproute2) / iptables         -> TUN routing setup
  #   - ps / kill (procps)               -> managing the bundled cores
  runtimeDeps = with pkgs; [
    coreutils
    lsb-release
    net-tools
    iproute2
    iptables
    procps
  ];

  # Happ bundles its own libxkbcommon, built by the vendor (Debian/Ubuntu) with
  # the default XKB data root baked in as /usr/share/X11/xkb -- a path that does
  # not exist on NixOS. When Happ runs under XWayland/xcb (which it does whenever
  # its bundled Qt6 Wayland plugin can't drive the compositor, e.g. wlroots), the
  # xcb backend asks that libxkbcommon to build a keymap, it finds no XKB data
  # anywhere, and returns a NULL xkb_state. The client then runs fine until the
  # first key press, when Qt calls xkb_state_key_get_one_sym() on that NULL state
  # and segfaults. Pointing XKB_CONFIG_ROOT at nixpkgs' xkeyboard-config gives the
  # bundled lib real data to compile, so the keymap (and thus every key press)
  # works. Harmless on the native-Wayland path, where the compositor supplies the
  # keymap over the wire and this variable is simply unused.
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

  # The vendor binaries ship their own complete, qt.conf-configured Qt6 runtime
  # and plugin tree, so wrapQtAppsHook's automatic postFixup wrapping is not
  # wanted here -- it would inject an unrelated nixpkgs Qt6 build's plugin path
  # into $out/bin/happ, stacking a second wrapper on top of the manual
  # wrapProgram call below. Keep the hook only to satisfy Qt's build-time
  # qtPreHook check (it errors if a Qt dependency is present without either
  # the hook or this flag).
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
      # Remove the bundled Wayland plugins before autoPatchelf/fixup even
      # sees them, so Qt has no native Wayland backend to fall back to.
      rm -rf $out/happ/lib/plugins/wayland-*
      rm -f $out/happ/lib/plugins/platforms/libqwayland-*.so
    ''}

    # Wrap both the GUI (Happ) and the privileged control daemon (happd).
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
    # Happ is distributed as a closed-source, freely redistributable binary.
    # The license field is intentionally left unset so importing this package
    # does not force `allowUnfree` on users that do not already enable it.
  };
}
