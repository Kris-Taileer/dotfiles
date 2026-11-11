{ pkgs, ... }:

# osu-lazer-bin ships the correct client hash (no notgne2 patch needed); its
# default XWayland renderer is smoother here than native Wayland.
let
  osu = pkgs.osu-lazer-bin;
in
{
  home.packages = [ osu ];

  # Routed through gamemoderun to avoid mid-map governor throttling on battery.
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
