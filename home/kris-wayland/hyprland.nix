{ config, lib, pkgs, inputs, ... }:
# macOS-like Hyprland rice — functionality-first pass.
# Sonoma-dark palette lives in `c` below; swap these values (and the Waybar /
# wofi CSS at the bottom) when the reference rice configs land.
let
  c = {
    bg       = "1e1e1e";  # window / base graphite
    text     = "ededed";
    subtext  = "a0a0a5";
    accent   = "0a84ff";  # macOS dark-mode blue
    border   = "ffffff";  # active border, used at low alpha
  };

  # Hyprland-native screenshots (driftshot is driftwm-only). Same UX/keys:
  # region -> satty annotator, screen/window -> straight to file + clipboard.
  hyprshot = pkgs.writeShellScriptBin "hyprshot" ''
    set -euo pipefail
    grim="${pkgs.grim}/bin/grim"
    slurp="${pkgs.slurp}/bin/slurp"
    satty="${pkgs.satty}/bin/satty"
    wlcopy="${pkgs.wl-clipboard}/bin/wl-copy"
    notify="${pkgs.libnotify}/bin/notify-send"
    hyprctl="${pkgs.hyprland}/bin/hyprctl"
    jq="${pkgs.jq}/bin/jq"

    mode="''${1:-region}"
    dir="''${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
    mkdir -p "$dir"
    file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

    finish() {
      "$wlcopy" --type image/png < "$file"
      "$notify" -a hyprshot -i "$file" "$1" "$file" || true
    }

    case "$mode" in
      screen|full|output)
        "$grim" "$file"; finish "Screenshot saved" ;;
      window)
        geom="$("$hyprctl" -j activewindow | "$jq" -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        "$grim" -g "$geom" "$file"; finish "Window captured" ;;
      region|area)
        geom="$("$slurp")" || exit 0
        "$grim" -g "$geom" - \
          | "$satty" --filename - --output-filename "$file" \
              --early-exit --copy-command "$wlcopy" ;;
      *)
        echo "usage: hyprshot [region|screen|window]" >&2; exit 2 ;;
    esac
  '';

  # Battery: drop the panel to 60Hz on battery, back to 120Hz on AC. Event-driven
  # (udev power_supply events) rather than polling, and idempotent (only calls
  # hyprctl when the AC state actually flips). Runs inside the session as an
  # exec-once, so hyprctl auto-resolves the instance.
  refreshSync = pkgs.writeShellScriptBin "refresh-sync" ''
    AC=/sys/class/power_supply/AC0/online
    hyprctl="${pkgs.hyprland}/bin/hyprctl"
    last=""
    apply() {
      on="$(cat "$AC" 2>/dev/null)"
      [ "$on" = "$last" ] && return
      last="$on"
      if [ "$on" = "1" ]; then
        "$hyprctl" keyword monitor "eDP-1,2880x1800@120,auto,1.333333"
      else
        "$hyprctl" keyword monitor "eDP-1,2880x1800@60,auto,1.333333"
      fi
    }
    apply
    ${pkgs.systemd}/bin/udevadm monitor --udev --subsystem-match=power_supply \
      | while read -r _; do apply; done
  '';

  # Apple-style Liquid Glass (refraction/specular/fresnel/chromatic-aberration).
  # Pinned to the hyprglass commit that hyprpm maps to Hyprland 0.55.4 — built
  # from source via mkHyprlandPlugin so it links to our Nix-store libs (prebuilt
  # .so's fail on NixOS: wrong soname / no libaquamarine in a standard path).
  hyprglass = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    pluginName = "hyprglass";
    version = "0.6.4";
    src = pkgs.fetchFromGitHub {
      owner = "hyprnux";
      repo = "hyprglass";
      rev = "7ff4064cbed1ef6e6f703139fca4ec20ba0cbb5b"; # hyprpm pin for hl 0.55.4
      hash = "sha256-e60+3KjFJOIi4DqcpxkeADsdApV+Cso2mwRA9t1Fs3U=";
    };
    dontConfigure = true;
    buildPhase = "make";
    installPhase = "mkdir -p $out/lib; cp hyprglass.so $out/lib/libhyprglass.so";
    meta = { description = "Apple-style Liquid Glass effect for Hyprland"; };
  };

  # White (monochrome) wlogout icons — the stock lock icon ships purple.
  wlogoutIcons = pkgs.runCommand "wlogout-white-icons"
    { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    mkdir -p $out
    for f in ${pkgs.wlogout}/share/wlogout/icons/*.png; do
      magick "$f" -channel RGB -fill white -colorize 100 "$out/$(basename "$f")"
    done
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # home.stateVersion 26.05 defaults configType to "lua", whose HM serializer
    # emits broken Lua for `$mod` / `exec-once`. Pin the classic hyprlang
    # (hyprland.conf) format — battle-tested and what every online config uses.
    configType = "hyprlang";
    # nixpkgs Hyprland + matching plugin build from the same nixpkgs — no
    # separate flake input, no long compile, stays on the binary cache.
    # hyprspace = a zoom-out overview of all workspaces (Mission Control).
    # hyprglass REMOVED: its layer-render hook makes waybar/plank surfaces
    # invisible just by loading (poisons layer compositing). Glass comes from
    # native Hyprland blur instead. Keep only hyprspace (Mission Control).
    plugins = [ pkgs.hyprlandPlugins.hyprspace pkgs.hyprlandPlugins.hyprbars ];

    settings = {
      "$mod" = "SUPER";

      # Mirrors the driftwm output layout so displays behave the same here.
      # Any external output duplicates (mirrors) the internal eDP-1 panel.
      monitor = [
        "eDP-1,preferred,auto,1.333333"
        "HDMI-A-1,preferred,auto,1,mirror,eDP-1"
        ",preferred,auto,1,mirror,eDP-1"
      ];

      env = [
        "XCURSOR_THEME,macOS"    # apple-cursor (global default is now macOS too)
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "TERMINAL,ghostty"       # default terminal for apps that honour $TERMINAL
      ];

      exec-once = [
        # Hand the Wayland session env to systemd + D-Bus so xdg-desktop-portal
        # (screen sharing, file pickers) and other user services work.
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
        # SSH agent / keyring, same handoff driftwm uses.
        "eval $(gnome-keyring-daemon --start --components=ssh) && systemctl --user import-environment SSH_AUTH_SOCK && dbus-update-activation-environment SSH_AUTH_SOCK"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "awww-daemon"
        "sleep 1 && awww img ~/.config/hypr/wallpaper.png"
        "qs"   # Quickshell macOS shell: menu bar + Dynamic Island notch + dock + control center
        "wl-paste --watch cliphist store"   # record clipboard history (SUPER+V picker)
        "waycorner"                         # macOS hot corners
        "refresh-sync"                      # 120Hz on AC / 60Hz on battery (battery saver)
        # idle/lock is handled by hypridle (services.hypridle in desktop.nix)
      ];

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 1;
        "col.active_border" = "rgba(${c.border}59)";   # ~35% white, subtle
        "col.inactive_border" = "rgba(${c.bg}00)";
        layout = "dwindle";
        resize_on_border = true;
      };

      decoration = {
        rounding = 12;
        # hyprglass: clearly translucent so the frosted blur reads at a glance.
        # xray = false → the blur shows the blurred windows *behind*, not just
        # the wallpaper (the classic layered-glass look). Costs a bit more GPU,
        # but this laptop handles it. Media/readability apps forced opaque below.
        active_opacity = 0.85;
        inactive_opacity = 0.70;
        dim_inactive = false;

        # Native blur ON — it glasses the bar / dock / launcher (layer
        # surfaces). hyprglass is windows-ONLY: its layer render hook makes
        # waybar surfaces invisible (bars vanish), so it must not touch layers.
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = true;
          ignore_opacity = true;
        };

        shadow = {
          enabled = true;
          range = 24;
          render_power = 2;
          color = "rgba(00000055)";
        };
      };

      # Snappy but smooth macOS-style easing (easeOutExpo-ish).
      animations = {
        enabled = true;
        bezier = [
          "macos, 0.16, 1, 0.3, 1"
          "smooth, 0.05, 0.9, 0.1, 1.0"
          "smoothOut, 0.36, 0, 0.66, -0.56"
        ];
        animation = [
          "windows, 1, 5, smooth, popin 92%"
          "windowsOut, 1, 5, smoothOut, popin 92%"
          "border, 1, 8, smooth"
          "fade, 1, 6, smooth"
          "layers, 1, 5, smooth, popin 90%"
          "workspaces, 1, 6, smooth, slide"
          "specialWorkspace, 1, 6, smooth, slidevert"
        ];
      };

      input = {
        kb_layout = "us,ru";
        kb_options = "grp:alt_shift_toggle";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = true;
          scroll_factor = 1.0;
        };
      };

      # 0.55 removed gestures:workspace_swipe / _fingers; these remain as tuning.
      gestures = {
        workspace_swipe_distance = 400;
        workspace_swipe_cancel_ratio = 0.2;
      };

      # Swipe is now enabled via the `gesture` keyword:
      #   3-finger horizontal = switch Spaces
      #   4-finger up         = Mission Control (macOS parity)
      # The dispatcher resolves at gesture time, after the plugin has loaded.
      gesture = [
        "3, horizontal, workspace"
        "4, down, dispatcher, overview:open"    # Mission Control: swipe down to open
        "4, up, dispatcher, overview:close"     # swipe up to close
      ];

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        # NOTE: misc:vrr and render:direct_scanout were REMOVED. On this eDP
        # panel (2880x1800@120Hz) they made the first atomic DRM modeset fail
        # with "Invalid argument" and loop page-flip commits (unusable display).
        # VFR is on by default in 0.55 and already covers the idle-power win.
      };

      dwindle = {
        preserve_split = true;
        # (dwindle:pseudotile was removed in 0.55; use the `pseudo` dispatcher)
      };

      # KZDKM/Hyprspace = the workspace overview (Mission Control).
      # Toggle via SUPER+grave or 4-finger swipe up.
      # macOS-style title bars — monochrome grey traffic-light buttons.
      plugin.hyprbars = {
        bar_height = 28;
        bar_color = "rgba(1e1e1ecc)";
        "col.text" = "rgba(edededff)";
        bar_text_font = "Monocraft";
        bar_text_size = 11;
        bar_text_align = "center";
        bar_part_of_window = true;
        bar_precedence_over_border = true;
        bar_padding = 12;
        bar_button_padding = 8;
        hyprbars-button = [
          "rgb(cfcfd2), 12, , hyprctl dispatch killactive"                          # close
          "rgb(9a9a9e), 12, , hyprctl dispatch fullscreen 1"                        # maximize
          "rgb(6a6a6e), 12, , hyprctl dispatch movetoworkspacesilent special:minimized"  # minimize
        ];
      };

      plugin.overview = {
        centerAligned = true;
        hideTopLayers = true;
        hideOverlayLayers = false;
        drawActiveWorkspace = true;
        showNewWorkspace = true;
        exitOnClick = true;
        exitOnSwitch = true;
        overrideAnimSpeed = 6;   # smoother/gentler open-close than the window default
      };

      # Liquid Glass (hyprglass). Tuned for a subtle Sonoma frosted look; blur
      # iterations kept low for battery. Also glasses the bar/dock/launcher.
      plugin.hyprglass = {
        enabled = 1;
        default_theme = "dark";
        blur_strength = 1.4;
        blur_iterations = 2;
        refraction_strength = 0.06;
        chromatic_aberration = 0.008;
        fresnel_strength = 0.4;
        specular_strength = 0.3;
        glass_opacity = 0.85;
        edge_thickness = 0.06;
        # layers MUST stay OFF: hyprglass's layer render hook makes the waybar
        # bars invisible. The bars get their glass from native blur instead.
        layers.enabled = 0;
      };

      # Real glass under the bar / launcher / dock. 0.55 syntax:
      #   `<effect> <value>, match:<prop> <regex>`  (ignorezero -> ignore_alpha)
      layerrule = [
        # Quickshell shell surfaces — frosted glass via native blur.
        "blur 1, match:namespace ^(qs-bar)$"
        "ignore_alpha 0.5, match:namespace ^(qs-bar)$"
        "blur 1, match:namespace ^(qs-dock)$"
        "ignore_alpha 0.4, match:namespace ^(qs-dock)$"
        "blur 1, match:namespace ^(qs-control-center)$"
        "ignore_alpha 0.4, match:namespace ^(qs-control-center)$"
        "blur 1, match:namespace ^(wofi)$"
        "ignore_alpha 0.5, match:namespace ^(wofi)$"
        "blur 1, match:namespace ^(swaync-control-center)$"
        "ignore_alpha 0.5, match:namespace ^(swaync-control-center)$"
        "blur 1, match:namespace ^(swaync-notification-window)$"
        "ignore_alpha 0.5, match:namespace ^(swaync-notification-window)$"
      ];

      # 0.55 window-rule syntax: `<effect> <value>, match:<prop> <regex>`.
      windowrule = [
        "float 1, match:class ^(pavucontrol)$"
        "float 1, match:class ^(org.pulseaudio.pavucontrol)$"
        "float 1, match:class ^(blueman-manager)$"
        "float 1, match:title ^(Picture-in-Picture)$"
        "float 1, match:title ^(Open File)$"
        "float 1, match:title ^(Save File)$"
        "suppress_event maximize, match:class .*"

        # Glass would wash these out — force them opaque.
        "opaque 1, match:class ^(mpv)$"
        "opaque 1, match:class ^(imv)$"
        "opaque 1, match:class ^(org.kde.gwenview)$"
        "opaque 1, match:class ^(org.pwmt.zathura)$"
        "opaque 1, match:class ^(gimp.*)$"
        "opaque 1, match:class ^(steam)$"
        "opaque 1, match:class ^(lutris)$"

        # Hero glass terminal — noticeably see-through.
        "opacity 0.78 0.62, match:class ^(Alacritty)$"

      ];

      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, T, exec, ghostty"
        "$mod, N, exec, ghostty -e nvim"           # glassy Neovim w/ cursor shader
        "$mod, Space, exec, wofi --show drun"      # Spotlight
        "$mod, D, exec, wofi --show drun"
        "$mod, Q, killactive"
        "$mod, F, fullscreen, 0"
        "$mod, E, togglefloating"
        "$mod, L, exec, hyprlock"
        # Mission Control. Bind to `exec` (an always-present dispatcher) rather
        # than the plugin's `overview:toggle` directly: the plugin loads after
        # config parse, and Hyprland DROPS binds whose dispatcher is unknown at
        # parse time. `hyprctl dispatch` resolves it at press time instead.
        "$mod, grave, exec, hyprctl dispatch overview:toggle"
        "$mod SHIFT, Escape, exit"                 # log out of Hyprland

        "$mod, P, exec, hyprshot region"
        "$mod SHIFT, P, exec, hyprshot screen"
        "$mod CTRL, P, exec, hyprshot window"

        # ---- macOS-style shortcuts ----
        "$mod, W, killactive"                                    # Cmd+W  close window
        "$mod ALT, Q, forcekillactive"                           # Cmd+Opt+Esc  force quit
        "CTRL $mod, Q, exec, hyprlock"                           # Ctrl+Cmd+Q  lock
        # (Ctrl+arrows intentionally left UNBOUND so apps get word-jump / native use)
        "ALT, Tab, cyclenext"                                    # Cmd+Tab     window switcher
        "ALT, Tab, bringactivetotop"
        "$mod, comma, movetoworkspacesilent, special:minimized" # Cmd+H       hide window
        "$mod SHIFT, comma, togglespecialworkspace, minimized"  #             peek/restore hidden
        "$mod, period, exec, bemoji -p -P 0"                    # emoji picker (no recent-history section)
        "$mod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"  # clipboard history
        "$mod SHIFT, N, exec, swaync-client -t -sw"             # toggle Notification Center
        "$mod, Escape, exec, wlogout -b 5 -T 50 -B 1140 -L 680 -R 680 -c 14 -r 14"  # compact top-center power menu
        "$mod SHIFT, C, exec, hyprpicker -a"                    # color picker → clipboard

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        "$mod, Tab, workspace, e+1"
        "$mod SHIFT, Tab, workspace, e-1"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
      ];

      # Volume keys use wpctl directly — the Dynamic Island notch is the volume
      # OSD (it reacts to any Pipewire change). Brightness keeps avizo's OSD via
      # lightctl (the notch doesn't surface brightness).
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86MonBrightnessUp, exec, lightctl up"
        ",XF86MonBrightnessDown, exec, lightctl down"
      ];

      bindl = [
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
    font = {
      name = "Monocraft";
      size = 11;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # libadwaita / GTK4 apps follow this; keeps everything dark without Plasma.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # Qt apps (Dolphin, Ark, Okular…) follow the GTK theme instead of defaulting
  # to a light Fusion look now that Plasma's platform theme is gone.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  home.packages = with pkgs; [
    # awww (swww fork) is already in packages.nix; it drives the wallpaper.
    # (apple-cursor is installed via home.pointerCursor in desktop.nix)
    hyprshot             # Hyprland-native screenshots (defined above)
    refreshSync          # 120/60Hz auto-switch on AC/battery (defined above)
    quickshell           # QtQuick Wayland shell (bar/notch/dock/control-center)
    hyprpicker
    playerctl
    bemoji               # emoji picker (SUPER+.)
    cliphist             # clipboard history (SUPER+V)
    wlogout              # power menu (SUPER+Escape)
    waycorner            # macOS hot corners
    polkit_gnome
    whitesur-gtk-theme
    whitesur-icon-theme
  ];

  home.file = {
    ".config/hypr/wallpaper.png".source = ./wallpapers/wallpaper.png;

    # ---- Quickshell macOS unified shell (QML) ----
    ".config/quickshell".source = ./quickshell;

    # ---- waycorner: macOS hot corners ----
    ".config/waycorner/config.toml".text = ''
      [mission-control]
      enter_command = ["hyprctl", "dispatch", "overview:toggle"]
      locations = ["top_right"]
      size = 10
      timeout_ms = 200

      [lock]
      enter_command = ["hyprlock"]
      locations = ["bottom_left"]
      size = 10
      timeout_ms = 500
    '';

    # ---- wlogout: macOS-style power menu (SUPER+Escape) ----
    ".config/wlogout/layout".text = ''
      { "label": "lock",     "action": "hyprlock",              "text": "Lock",     "keybind": "l" }
      { "label": "suspend",  "action": "systemctl suspend",     "text": "Sleep",    "keybind": "s" }
      { "label": "logout",   "action": "hyprctl dispatch exit", "text": "Log Out",  "keybind": "e" }
      { "label": "reboot",   "action": "systemctl reboot",      "text": "Restart",  "keybind": "r" }
      { "label": "shutdown", "action": "systemctl poweroff",    "text": "Shut Down","keybind": "p" }
    '';
    ".config/wlogout/style.css".text = ''
      * { font-family: "Monocraft", "JetBrainsMono Nerd Font"; color: #e8e8ea; }
      window { background: rgba(16, 16, 18, 0.5); }
      button {
        background-color: rgba(44, 44, 46, 0.85);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 20px;
        margin: 8px;
        background-repeat: no-repeat;
        background-position: center 30%;
        background-size: 26%;
        outline: none;
        transition: all 150ms ease;
      }
      button:focus, button:hover {
        background-color: rgba(255, 255, 255, 0.16);   /* monochrome hover */
        border-color: rgba(255, 255, 255, 0.30);
      }
      #lock     { background-image: image(url("${wlogoutIcons}/lock.png")); }
      #logout   { background-image: image(url("${wlogoutIcons}/logout.png")); }
      #suspend  { background-image: image(url("${wlogoutIcons}/suspend.png")); }
      #reboot   { background-image: image(url("${wlogoutIcons}/reboot.png")); }
      #shutdown { background-image: image(url("${wlogoutIcons}/shutdown.png")); }
    '';


    ".config/waybar-mac/config.jsonc".text = builtins.toJSON {
      name = "top";
      layer = "top";
      position = "top";
      height = 26;
      spacing = 6;
      modules-left = [ "custom/apple" "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ ];
      modules-right = [ "tray" "backlight" "pulseaudio" "network" "battery" "clock" ];

      "custom/apple" = {
        format = "";
        tooltip = false;
        on-click = "wofi --show drun";
      };
      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "●";
          default = "○";
        };
        on-click = "activate";
      };
      "hyprland/window" = {
        format = "{title}";
        max-length = 60;
        separate-outputs = true;
      };
      clock = {
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
      };
      # Brightness: scroll over it to change; icon dims/brightens with level.
      backlight = {
        format = "{icon} {percent}%";
        format-icons = [ "󰃞" "󰃟" "󰃠" ];
        tooltip-format = "Brightness {percent}%";
        on-scroll-up = "brightnessctl set +5%";
        on-scroll-down = "brightnessctl set 5%-";
      };
      # Volume: scroll to change, click for mixer, right-click to mute.
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 0%";
        format-icons = { default = [ "󰕿" "󰖀" "󰕾" ]; };
        tooltip-format = "Volume {volume}%";
        scroll-step = 5;
        on-click = "pavucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
      network = {
        format-wifi = "󰖩 {signalStrength}%";
        format-ethernet = "󰈀";
        format-disconnected = "󰖪";
        tooltip-format = "{ifname}: {ipaddr}";
      };
      battery = {
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons = [ "󰁺" "󰁼" "󰁾" "󰂀" "󰂂" "󰁹" ];
      };
      tray = {
        icon-size = 16;
        spacing = 8;
      };
    };

    ".config/waybar-mac/style.css".text = ''
      * {
        font-family: "Monocraft", "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }
      window#waybar {
        background: rgba(30, 30, 30, 0.55);
        color: #${c.text};
        border-bottom: 1px solid rgba(255, 255, 255, 0.06);
      }
      /* nudge all bar content ~2px down so icons sit vertically centred */
      window#waybar label { margin-top: 2px; }
      #custom-apple {
        padding: 0 12px;
        font-size: 15px;
        color: #ffffff;
      }
      #workspaces button {
        padding: 0 4px;
        font-size: 10px;
        color: #${c.subtext};
        background: transparent;
      }
      #workspaces button.active {
        color: #ffffff;
        background: transparent;
      }
      #window {
        color: #${c.text};
        font-weight: 600;
      }
      /* status icons: force the Nerd Font so glyphs never render as blank */
      #clock, #battery, #network, #pulseaudio, #backlight, #tray {
        font-family: "Monocraft", "JetBrainsMono Nerd Font";
        padding: 0 8px;
        color: #${c.text};
        border-radius: 8px;
      }
      #clock { font-family: "Monocraft", "JetBrainsMono Nerd Font"; font-weight: 600; }
      #backlight { color: #ffd479; }
      #pulseaudio { color: #7fd6c2; }
      #network { color: #8fc6ff; }
      #battery.charging { color: #${c.accent}; }
      #battery.critical:not(.charging) { color: #ff5f57; }
      #pulseaudio.muted { color: #${c.subtext}; }
      #network.disconnected { color: #ff5f57; }
      /* subtle hover on the status cluster — feels "alive" without chips */
      #backlight:hover, #pulseaudio:hover, #network:hover, #battery:hover, #clock:hover {
        background: rgba(255, 255, 255, 0.10);
      }

      /* ---- bottom dock (pinned apps) ---- */
      window#waybar.dock { background: transparent; border: none; }
      window#waybar.dock .modules-center {
        background: rgba(40, 40, 42, 0.5);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 24px;
        padding: 4px 10px;
        margin-bottom: 6px;
      }
      window#waybar.dock #image {
        padding: 3px 10px;
        border-radius: 14px;
        transition: all 150ms ease;
      }
      window#waybar.dock #image:hover {
        background: rgba(255, 255, 255, 0.16);
      }
    '';

    ".config/nwg-dock-hyprland/style.css".text = ''
      window {
        background: rgba(40, 40, 42, 0.5);
        border-radius: 22px;
        border: 1px solid rgba(255, 255, 255, 0.1);
        padding: 4px;
      }
      button {
        border-radius: 14px;
        margin: 4px;
        padding: 4px;
        transition: all 150ms ease;
      }
      button:hover {
        background: rgba(255, 255, 255, 0.16);
      }
    '';

    ".config/wofi/config".text = ''
      show=drun
      width=720
      lines=9
      line_wrap=off
      term=ghostty
      insensitive=true
      allow_images=true
      image_size=34
      prompt=krislight
      key_expand=Tab
    '';

    ".config/wofi/style.css".text = ''
      window {
        margin: 0;
        border-radius: 18px;
        background: rgba(30, 30, 30, 0.7);
        border: 1px solid rgba(255, 255, 255, 0.08);
        font-family: "Monocraft", "JetBrainsMono Nerd Font";
        font-size: 16px;
      }
      #input {
        margin: 14px;
        padding: 14px;
        border-radius: 12px;
        background: rgba(255, 255, 255, 0.08);
        color: #ffffff;
        border: none;
        font-size: 17px;
      }
      #inner-box { margin: 10px; }
      #outer-box { margin: 0; }
      #scroll { margin: 0; }
      #entry {
        padding: 11px 16px;
        border-radius: 12px;
      }
      #entry:selected {
        background: rgba(255, 255, 255, 0.14);
      }
      #text { color: #${c.text}; }
      #entry:selected #text { color: #ffffff; }
    '';
  };
}
