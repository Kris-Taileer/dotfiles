{ pkgs, ... }:
let
  colors = import ./theme.nix;
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.95;
      font = {
        normal.family = "JetBrainsMono Nerd Font";
        size = 12;
      };
      colors = {
        primary = {
          background = "#${colors.base}";
          foreground = "#${colors.text}";
        };
        normal = {
          black   = "#${colors.surface1}";
          red     = "#${colors.red}";
          green   = "#${colors.green}";
          yellow  = "#${colors.yellow}";
          blue    = "#${colors.blue}";
          magenta = "#${colors.mauve}";
          cyan    = "#${colors.teal}";
          white   = "#${colors.subtext1}";
        };
        bright = {
          black   = "#${colors.overlay0}";
          red     = "#${colors.maroon}";
          green   = "#${colors.green}";
          yellow  = "#${colors.peach}";
          blue    = "#${colors.sapphire}";
          magenta = "#${colors.pink}";
          cyan    = "#${colors.sapphire}";
          white   = "#${colors.text}";
        };
      };
    };
  };

  home.file.".config/fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": { "type": "small" },
      "display": { "separator": " → " },
      "modules": [
        "title", "separator", "os", "host", "kernel", "uptime",
        "packages", "shell", "wm", "terminal", "cpu", "memory", "break", "colors"
      ]
    }
  '';
}
