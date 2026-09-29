{ pkgs, ... }:
let
  colors = import ./theme.nix;

  avizoWhite = pkgs.avizo.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.imagemagick ];
    postPatch = (old.postPatch or "") + ''
      for f in data/images/*.svg; do
        sed -i 's/#[0-9a-fA-F]\{6\}/#ffffff/g' "$f"
      done
      for f in data/images/*.png; do
        magick "$f" -channel RGB -fill white -colorize 100 "$f"
      done
    '';
  });
  rofiTheme = pkgs.writeText "rofi-theme.rasi" ''
    * {
      bg:     #0d0e1a;
      bg-alt: #1a1830;
      fg:     #f5f3ff;
      accent: #ff5fc4;
    }
    window {
      background-color: @bg;
      border:           2px solid;
      border-color:     @accent;
      border-radius:    10px;
      width:            480px;
    }
    element {
      padding:       6px 10px;
      border-radius: 6px;
    }
    element normal.normal {
      background-color: @bg;
      text-color:       @fg;
    }
    element selected.normal {
      background-color: @accent;
      text-color:       @bg;
    }
    element-text, element-icon {
      background-color: inherit;
      text-color:       inherit;
    }
    inputbar {
      background-color: @bg-alt;
      padding:          8px 12px;
      border-radius:    8px;
    }
  '';
in
{

  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      control-center-margin-top = 10;
      control-center-margin-right = 10;
      control-center-margin-bottom = 10;
      control-center-width = 400;
      notification-window-width = 400;
      timeout = 8;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = false;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      widgets = [ "title" "dnd" "notifications" ];
      widget-config = {
        title = { text = "Notifications"; clear-all-button = true; button-text = "Clear all"; };
        dnd = { text = "Do Not Disturb"; };
      };
    };
    style = ''
      * { font-family: "Monocraft", "JetBrainsMono Nerd Font"; }
      .control-center {
        background: rgba(28, 28, 30, 0.9);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 18px;
        color: #ededed;
      }
      .control-center-list { background: transparent; }
      .notification, .notification-row .notification-background .notification {
        background: rgba(44, 44, 46, 0.9);
        border: 1px solid rgba(255, 255, 255, 0.06);
        border-radius: 14px;
        margin: 6px 8px;
        padding: 4px;
      }
      .notification-content { color: #ededed; padding: 6px; }
      .summary { color: #ffffff; font-weight: 600; }
      .close-button {
        background: rgba(255, 255, 255, 0.12);
        border-radius: 100%;
        color: #ededed;
        margin: 4px;
      }
      .widget-title { color: #ededed; font-weight: 600; margin: 10px 12px 4px 12px; }
      .widget-title > button {
        background: rgba(255, 255, 255, 0.1);
        border-radius: 10px;
        color: #ededed;
        padding: 4px 12px;
      }
      .widget-dnd { color: #ededed; margin: 4px 12px; }
      .widget-dnd > switch {
        background: rgba(255, 255, 255, 0.14);
        border-radius: 100px;
      }
      .widget-dnd > switch:checked { background: rgba(255, 255, 255, 0.55); }
      .floating-notifications .notification {
        background: rgba(28, 28, 30, 0.9);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 16px;
      }
    '';
  };

  services.avizo = {
    enable = true;
    package = avizoWhite;
    settings.default = {
      time = 1.2;
      y-offset = 0.12;
      fade-in = 0.1;
      fade-out = 0.25;
      padding = 14;
      border-radius = 18;
      border-width = 1;
      border-color = "rgba(255, 255, 255, 0.12)";
      background = "rgba(28, 28, 30, 0.9)";
      bar-fg-color = "rgba(255, 255, 255, 0.92)";
      bar-bg-color = "rgba(255, 255, 255, 0.14)";
      block-height = 8;
      block-spacing = 3;
      block-count = 20;
    };
  };

  programs.rofi = {
    enable = true;
    terminal = "alacritty";
    theme = "${rofiTheme}";
  };
}
