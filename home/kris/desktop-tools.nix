{ pkgs, ... }:
let
  colors = import ./theme.nix;
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
    theme = {
      "*" = {
        bg = "#${colors.base}";
        bg-alt = "#${colors.surface0}";
        fg = "#${colors.text}";
        accent = "#${colors.pink}";
      };
      "window" = {
        background-color = "@bg";
        border = 2;
        border-color = "@accent";
        border-radius = 10;
        width = 480;
      };
      "element-text, element-icon" = {
        background-color = "inherit";
        text-color = "inherit";
      };
      "element selected" = {
        background-color = "@accent";
        text-color = "@bg";
      };
      "inputbar" = {
        background-color = "@bg-alt";
        padding = "8px 12px";
        border-radius = 8;
      };
    };
  };
}
