{ pkgs, ... }:
let
  colors = import ./theme.nix;
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
  services.dunst = {
    enable = true;
    settings = {
      # Sonoma-dark glass: translucent graphite (the ~e6 alpha lets the
      # Hyprland `notifications` blur rule frost it), subtle white hairline.
      global = {
        width = 360;
        height = 110;
        origin = "top-right";
        offset = "14x14";
        frame_width = 1;
        frame_color = "#ffffff26";
        separator_color = "frame";
        font = "Monocraft 10";
        corner_radius = 16;
        background = "#1e1e1ee6";
        foreground = "#ededed";
        padding = 14;
        horizontal_padding = 16;
        text_icon_padding = 10;
        gap_size = 8;
      };
      urgency_low = {
        background = "#1e1e1ecc";
        foreground = "#a0a0a5";
        frame_color = "#ffffff1a";
        timeout = 5;
      };
      urgency_normal = {
        background = "#1e1e1ee6";
        foreground = "#ededed";
        frame_color = "#ffffff26";
        timeout = 8;
      };
      urgency_critical = {
        background = "#2a1416e6";
        foreground = "#ffffff";
        frame_color = "#ff5f57aa";
        timeout = 0;
      };
    };
  };

  programs.rofi = {
    enable = true;
    terminal = "alacritty";
    theme = "${rofiTheme}";
  };
}
