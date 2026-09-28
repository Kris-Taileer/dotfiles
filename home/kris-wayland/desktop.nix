{ config, pkgs, ... }:
{
  programs.hyprlock = {
    enable = true;
    # macOS Sonoma-style lock: the wallpaper as a heavily-blurred, dimmed
    # "frosted curtain", a large clock with the date above it in the upper third,
    # and a minimal password pill that stays hidden until you type — so at rest
    # it's only time + date + background.
    extraConfig = ''
      general {
        hide_cursor = true
      }

      # require the password immediately on lock (grace is a top-level option)
      grace = 0

      # frosted curtain = the wallpaper itself, lightly blurred (NOT dimmed to
      # black — the wallpaper is a dark space scene, so keep brightness ~full so
      # the accretion disk still glows through).
      background {
        monitor =
        path = ${config.home.homeDirectory}/.config/hypr/wallpaper.png
        blur_passes = 2
        blur_size = 6
        noise = 0.01
        contrast = 1.0
        brightness = 0.92
        vibrancy = 0.15
      }

      # date — small, above the clock (macOS/iOS order)
      label {
        monitor =
        text = cmd[update:60000] date +'%A, %-d %B'
        color = rgba(ededede6)
        font_size = 21
        font_family = Monocraft
        position = 0, 348
        halign = center
        valign = center
      }

      # time — large, upper third
      label {
        monitor =
        text = cmd[update:1000] date +'%H:%M'
        color = rgba(ffffffff)
        font_size = 120
        font_family = Monocraft
        position = 0, 232
        halign = center
        valign = center
      }

      # minimal password pill — lower centre, invisible until you type
      input-field {
        monitor =
        size = 300, 52
        outline_thickness = 2
        dots_size = 0.28
        dots_spacing = 0.32
        dots_center = true
        rounding = 26
        outer_color = rgba(ffffff33)
        inner_color = rgba(ffffff24)
        font_color = rgba(edededff)
        check_color = rgba(0a84ffff)
        fail_color = rgba(ff5f57ff)
        capslock_color = rgba(ffd479ff)
        fade_on_empty = true
        fade_timeout = 1000
        placeholder_text =
        fail_text = $FAIL
        position = 0, -360
        halign = center
        valign = center
      }
    '';
  };
  # macOS-style staged idle: dim → lock (hyprlock clock) → screen off → suspend.
  # (Wayland has no animated screensaver; hyprlock's clock is the "screensaver".)
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "applelock";   # macOS curtain lock (flock-deduped)
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        { timeout = 150; on-timeout = "brightnessctl -s set 10%"; on-resume = "brightnessctl -r"; }
        { timeout = 300; on-timeout = "loginctl lock-session"; }
        { timeout = 330; on-timeout = "hyprctl dispatch dpms off"; on-resume = "hyprctl dispatch dpms on"; }
        { timeout = 600; on-timeout = "systemctl suspend"; }
      ];
    };
  };

  home.pointerCursor = {
    enable  = true;
    package = pkgs.apple-cursor;   # ful1e5/apple_cursor
    name    = "macOS";
    size    = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  xdg.dataFile."applications/ida-pro.desktop".text = ''
    [Desktop Entry]
    Name=IDA Pro
    Exec=/home/kris/ida-pro-9.3/ida-launch.sh
    Icon=/home/kris/ida-pro-9.3/appico.png
    Terminal=false
    Type=Application
    Categories=Development;Debugger;
  '';

  xdg.dataFile."applications/nvim-term.desktop".text = ''
    [Desktop Entry]
    Name=Neovim
    Exec=ghostty -e nvim %F
    Terminal=false
    Type=Application
    MimeType=text/plain;text/x-python;text/x-csrc;text/x-chdr;text/javascript;application/json;text/x-shellscript;text/x-lua;text/x-rust;text/markdown;text/css;text/x-makefile;
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory"                = "dolphin.desktop";

      "image/jpeg"                     = "imv.desktop";
      "image/png"                      = "imv.desktop";
      "image/gif"                      = "imv.desktop";
      "image/webp"                     = "imv.desktop";
      "image/bmp"                      = "imv.desktop";
      "image/tiff"                     = "imv.desktop";
      "image/svg+xml"                  = "imv.desktop";
      "video/mp4"                      = "mpv.desktop";
      "video/webm"                     = "mpv.desktop";
      "video/x-matroska"               = "mpv.desktop";
      "video/x-msvideo"                = "mpv.desktop";
      "video/quicktime"                = "mpv.desktop";
      "audio/mpeg"                     = "mpv.desktop";
      "audio/ogg"                      = "mpv.desktop";
      "audio/flac"                     = "mpv.desktop";
      "audio/wav"                      = "mpv.desktop";
      "audio/aac"                      = "mpv.desktop";
      "audio/x-wav"                    = "mpv.desktop";
      "application/pdf"                = "org.pwmt.zathura.desktop";
      "application/zip"                = "ark.desktop";
      "application/x-tar"              = "ark.desktop";
      "application/gzip"               = "ark.desktop";
      "application/x-7z-compressed"    = "ark.desktop";
      "application/x-rar"              = "ark.desktop";
      "application/x-bittorrent"       = "org.qbittorrent.qBittorrent.desktop";
      "x-scheme-handler/magnet"        = "org.qbittorrent.qBittorrent.desktop";
      "text/plain"                     = "dev.zed.Zed.desktop";
      "text/x-python"                  = "dev.zed.Zed.desktop";
      "text/x-csrc"                    = "dev.zed.Zed.desktop";
      "text/x-chdr"                    = "dev.zed.Zed.desktop";
      "text/javascript"                = "dev.zed.Zed.desktop";
      "application/json"               = "dev.zed.Zed.desktop";
      "text/x-shellscript"             = "dev.zed.Zed.desktop";
      "text/x-lua"                     = "dev.zed.Zed.desktop";
      "text/x-rust"                    = "dev.zed.Zed.desktop";
      "text/markdown"                  = "dev.zed.Zed.desktop";
      "text/css"                       = "dev.zed.Zed.desktop";
    };
  };
  xdg.configFile."kscreenlockerrc".text = ''
    [Daemon]
    Autolock=true
    LockOnResume=true
    Timeout=5
  '';

	home.file.".config/driftwm/config.toml".source = ./driftwm/config.toml;
	home.file.".config/driftwm/gray.glsl".source = ./driftwm/gray.glsl;
	home.file.".config/driftwm/foot-widget.ini".source = ./driftwm/foot-widget.ini;
	home.file.".config/driftwm/pyramid.glsl".source = ./driftwm/pyramid.glsl;
	home.file.".config/driftwm/event_horizon.glsl".source = ./driftwm/event_horizon.glsl;
	home.file.".config/driftwm/aurora_curtain.glsl".source = ./driftwm/aurora_curtain.glsl;
	home.file.".config/driftwm/radiant_geometry.glsl".source = ./driftwm/radiant_geometry.glsl;
	home.file.".config/driftwm/widgets".source = ./driftwm/widgets;
	home.file.".config/driftwm/screensaver".source = ./driftwm/screensaver;
}
