{ pkgs, ... }:

# osu!lazer, tuned for stable frametimes on the Intel iGPU laptop.
#
# Package choice: `osu-lazer-bin` (the official AppImage repackaged) rather than
# the source-built `osu-lazer`. The -bin build ships the correct client hash, so
# score submission and multiplayer work out of the box — this is why the
# notgne2/osu-nixos hash patch is unnecessary here.
#
# Renderer: the -bin package defaults to XWayland (SDL_VIDEODRIVER=x11). We keep
# that on purpose: native Wayland currently has higher input latency and
# fullscreen stutter with osu!lazer, while XWayland under KWin/driftwm is smooth.
# To experiment with native Wayland, use `pkgs.osu-lazer-bin.override { nativeWayland = true; }`.
let
  osu = pkgs.osu-lazer-bin;
in
{
  home.packages = [ osu ];

  # Shadow the launcher shipped by the package (same basename, so this wins in
  # ~/.local/share/applications) to route every menu/wofi/fuzzel launch through
  # gamemoderun. gamemode flips the CPU governor to `performance` and reduces
  # scheduler latency for the duration of play — the single biggest stability
  # win on a laptop, where the default `powersave` governor throttles mid-map.
  xdg.desktopEntries."osu!" = {
    name = "osu!";
    genericName = "Rhythm Game";
    comment = "osu!lazer — launched via gamemode for stable frametimes";
    exec = "${pkgs.gamemode}/bin/gamemoderun ${osu}/bin/osu! %U";
    icon = "osu!";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
    mimeType = [
      "application/x-osu-beatmap-archive"
      "application/x-osu-skin-archive"
      "x-scheme-handler/osu"
    ];
    settings.StartupWMClass = "osu!";
  };
}
