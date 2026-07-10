{ pkgs, ... }:
let
  colors = import ./theme.nix;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = false;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        margin-top = 8;
        margin-left = 12;
        margin-right = 12;
        spacing = 4;

        modules-left = [ "clock" "custom/separator" "cpu" "memory" "temperature" ];
        modules-center = [ "clock#big" ];
        modules-right = [ "tray" "pulseaudio" "network" "battery" "custom/lock" "custom/power" ];

        clock = {
          format = "  {:%H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "clock#big" = {
          format = "{:%A, %d %B}";
          interval = 60;
        };

        cpu = {
          format = "  {usage}%";
          interval = 2;
          tooltip = false;
        };

        memory = {
          format = "  {used:0.1f}G/{total:0.1f}G";
          interval = 5;
        };

        temperature = {
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = [ "" "" "" ];
        };

        network = {
          format-wifi = "  {essid} ({signalStrength}%)";
          format-ethernet = "  {ifname}";
          format-linked = "  {ifname} (no IP)";
          format-disconnected = "⚠ disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "  muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
          scroll-step = 5;
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "  {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };

        "custom/lock" = {
          format = "";
          on-click = "hyprlock";
          tooltip-format = "Lock screen";
        };

        "custom/power" = {
          format = "⏻";
          on-click = "systemctl poweroff";
          on-click-right = "systemctl reboot";
          tooltip-format = "Left click: shutdown\nRight click: reboot";
        };

        "custom/separator" = {
          format = "|";
          tooltip = false;
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
      }

      #waybar {
        background-color: alpha(#${colors.base}, 0.9);
        border: 2px solid #${colors.mauve};
        border-radius: 12px;
        color: #${colors.text};
      }

      #clock,
      #cpu,
      #memory,
      #temperature,
      #network,
      #pulseaudio,
      #battery,
      #custom-lock,
      #custom-power,
      #custom-separator {
        padding: 0 10px;
        margin: 4px 2px;
        border-radius: 8px;
        background-color: #${colors.surface0};
        color: #${colors.text};
      }

      #clock {
        color: #${colors.pink};
        font-weight: bold;
      }

      #clock.big {
        background: transparent;
        color: #${colors.lavender};
      }

      #cpu { color: #${colors.sapphire}; }
      #memory { color: #${colors.teal}; }
      #temperature { color: #${colors.peach}; }
      #temperature.critical { color: #${colors.red}; }

      #network { color: #${colors.blue}; }
      #network.disconnected { color: #${colors.red}; }

      #pulseaudio { color: #${colors.green}; }
      #pulseaudio.muted { color: #${colors.overlay0}; }

      #battery { color: #${colors.yellow}; }
      #battery.charging { color: #${colors.green}; }
      #battery.warning:not(.charging) { color: #${colors.peach}; }
      #battery.critical:not(.charging) {
        color: #${colors.red};
        animation: blink 1s linear infinite alternate;
      }

      @keyframes blink {
        to {
          background-color: #${colors.red};
          color: #${colors.base};
        }
      }

      #tray {
        background-color: transparent;
      }

      #custom-lock {
        color: #${colors.sapphire};
      }

      #custom-power {
        color: #${colors.maroon};
        font-size: 15px;
      }

      #custom-separator {
        color: #${colors.overlay0};
        background-color: transparent;
        padding: 0 2px;
      }
    '';
  };
}
