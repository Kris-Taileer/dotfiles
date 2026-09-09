{ config, lib, pkgs, ... }:
let
  cfg = config.services.bluetooth-setup;
in
{
  options.services.bluetooth-setup = {
    enable = lib.mkEnableOption "Bluetooth with A2DP audio, tray applet and a TUI client";

    user = lib.mkOption {
      type = lib.types.str;
      default = "kris";
      description = "User to grant Bluetooth access.";
    };

    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Power on the adapter at boot instead of leaving it soft-blocked.";
    };

    applet = lib.mkOption {
      type = lib.types.enum [ "blueman" "none" ];
      default = "blueman";
      description = "Tray applet for pairing/connecting from the desktop.";
    };

    tuiClient = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install bluetuith, a keyboard-driven TUI for pairing/connecting.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = cfg.powerOnBoot;
      settings.General = {
        # A2DP sink/source so headphones and speakers show up as audio devices.
        Enable = "Source,Sink,Media,Socket";
        # Needed for battery-level reporting (blueman/bluetuith) and LE features.
        Experimental = true;
        FastConnectable = true;
      };
    };

    services.blueman.enable = cfg.applet == "blueman";

    environment.systemPackages = lib.optional cfg.tuiClient pkgs.bluetuith;

    users.users.${cfg.user}.extraGroups = [ "bluetooth" ];
  };
}
