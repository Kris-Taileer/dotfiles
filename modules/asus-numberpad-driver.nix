{ config, lib, pkgs, ... }:

let
  cfg = config.services.asus-numberpad-driver;

  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    numpy
    libevdev
    xlib
    pyinotify
    pyasyncore
    pywayland
    xkbcommon
    systemd-python
    xcffib
    python-periphery
  ]);

  driverSrc = pkgs.fetchFromGitHub {
    owner = "asus-linux-drivers";
    repo = "asus-numberpad-driver";
    rev = "c57ad483960cd54e455ab3015cceb9364e128836";
    hash = "sha256-bofWcv66XzdyYEBBGiU7hAQkgqpxSRAEy2PnLFkqJJw=";
  };

  driverPkg = pkgs.stdenv.mkDerivation {
    pname = "asus-numberpad-driver";
    version = "7.0.2";
    src = driverSrc;

    buildInputs = with pkgs; [
      pythonEnv
      ibus
      libevdev
      i2c-tools
      libxkbcommon
    ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/asus-numberpad-driver
      cp numberpad.py $out/share/asus-numberpad-driver/
      cp -r layouts $out/share/asus-numberpad-driver/
      rm -rf $out/share/asus-numberpad-driver/layouts/__pycache__

      mkdir -p $out/bin
      cat > $out/bin/asus-numberpad-driver <<EOF
      #!${pkgs.bash}/bin/bash
      exec ${pythonEnv}/bin/python3 $out/share/asus-numberpad-driver/numberpad.py "\$@"
      EOF
      chmod +x $out/bin/asus-numberpad-driver
    '';
  };

  configDir = "/etc/asus-numberpad-driver";
in {
  options.services.asus-numberpad-driver = {
    enable = lib.mkEnableOption "ASUS NumberPad touchpad driver";

    layout = lib.mkOption {
      type = lib.types.str;
      default = "up5401ea";
      description = "Numberpad layout identifier (e.g. up5401ea).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "kris";
      description = "User to run the service as (must own the Wayland session).";
    };

    wayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    waylandDisplay = lib.mkOption {
      type = lib.types.str;
      default = "wayland-1";
    };

    runtimeDir = lib.mkOption {
      type = lib.types.str;
      default = "/run/user/1000/";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [ "uinput" "i2c-dev" ];
    hardware.i2c.enable = true;

    users.groups.uinput = {};

    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="uinput", MODE="0660"
      SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
    '';

    users.users.${cfg.user}.extraGroups = [ "i2c" "uinput" "input" ];

    systemd.tmpfiles.rules = [
      "d ${configDir} 0755 root root -"
      "d /var/log/asus-numberpad-driver 0755 root root -"
    ];

    environment.etc."asus-numberpad-driver/numberpad_dev".text = "[main]\n";

    systemd.services.asus-numberpad-driver = {
      description = "ASUS NumberPad Driver";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      startLimitBurst = 20;
      startLimitIntervalSec = 300;
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        ExecStart = "${driverPkg}/bin/asus-numberpad-driver ${cfg.layout} ${configDir}";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "XDG_SESSION_TYPE=${if cfg.wayland then "wayland" else "x11"}"
          "XDG_RUNTIME_DIR=${cfg.runtimeDir}"
          "WAYLAND_DISPLAY=${cfg.waylandDisplay}"
        ];
      };
    };
  };
}
