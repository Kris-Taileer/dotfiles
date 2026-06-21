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
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;

    shadow = true;
    shadowOpacity = 0.6;

    fade = true;
    fadeDelta = 4;

    settings = {
      corner-radius = 10;
      round-borders = 1;
      blur-method = "dual_kawase";
      blur-strength = 5;
      shadow-radius = 16;
      shadow-offset-x = -16;
      shadow-offset-y = -16;
    };
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 320;
        height = 80;
        origin = "top-right";
        offset = "12x12";
        frame_width = 2;
        frame_color = "#${colors.mauve}";
        font = "JetBrainsMono Nerd Font 10";
        corner_radius = 10;
        background = "#${colors.base}";
        foreground = "#${colors.text}";
      };
      urgency_low = {
        background = "#${colors.base}";
        foreground = "#${colors.subtext1}";
        frame_color = "#${colors.surface1}";
        timeout = 5;
      };
      urgency_normal = {
        background = "#${colors.base}";
        foreground = "#${colors.text}";
        frame_color = "#${colors.sapphire}";
        timeout = 8;
      };
      urgency_critical = {
        background = "#${colors.base}";
        foreground = "#${colors.text}";
        frame_color = "#${colors.red}";
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
