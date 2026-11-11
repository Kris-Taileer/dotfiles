{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption mkOption types stringAfter;
  cfg = config.services.happ;
in
{
  options.services.happ = {
    enable = mkEnableOption "Happ proxy desktop client and background TUN daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./happ.nix { inherit (cfg) forceXwayland forceSoftwareRendering; };
      defaultText = "pkgs.callPackage ./happ.nix { }";
      description = "The Happ package to use.";
    };

    forceXwayland = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Force Happ to run through XWayland (XCB) instead of its bundled Qt6
        Wayland plugins, which are dropped from the package entirely. Works
        around a silent startup crash on wlroots-based Wayland compositors
        (Hyprland, Sway, ...) where the bundled Qt6 Wayland integration is
        incompatible. Only affects the default `package` build above; has
        no effect if you override `services.happ.package` yourself.
      '';
    };

    forceSoftwareRendering = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Force Happ's Qt Quick UI to render in software (`QML_SCENE_GRAPH=software`,
        `LIBGL_ALWAYS_SOFTWARE=1`). Independent of `forceXwayland` -- use this if
        Happ's UI renders incorrectly or not at all due to a GPU/driver issue,
        regardless of which Qt platform backend is in use. Only affects the
        default `package` build above; has no effect if you override
        `services.happ.package` yourself.
      '';
    };

    tunInterface = mkOption {
      type = types.str;
      default = "tun0";
      description = ''
        Name of the TUN interface Happ brings up; it is added to the firewall's
        trusted interfaces so tunnelled traffic is not dropped.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.net-tools
      pkgs.lsb-release
    ];

    # dbus-broker doesn't create /var/lib/dbus/machine-id, leaving Happ's HWID blank; link it.
    # happd below must stay unsandboxed -- ProtectSystem/PrivateTmp breaks this bind-mount (226/NAMESPACE).
    systemd.tmpfiles.rules = [
      "L+ /var/lib/dbus/machine-id - - - - /etc/machine-id"
    ];

    networking.firewall.checkReversePath = "loose";
    networking.firewall.trustedInterfaces = [ cfg.tunInterface ];
    boot.kernelModules = [ "tun" ];

    # Materialised read-only, not world-writable -- it would let any local user replace
    # the happd binary that systemd runs as root below.
    system.activationScripts.happ-opt = stringAfter [ "stdio" ] ''
      stamp=/opt/happ/.nix-store-path
      if [ "$(cat "$stamp" 2>/dev/null)" != "${cfg.package}" ]; then
        rm -rf /opt/happ
        mkdir -p /opt/happ
        cp -r ${cfg.package}/happ/. /opt/happ/
        chown -R root:root /opt/happ
        chmod -R u=rwX,go=rX /opt/happ
        printf '%s' "${cfg.package}" > "$stamp"
      fi
    '';

    systemd.services.happd = {
      description = "Happ Process Control Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      # ExecStart is a fixed /opt/happ path, not a Nix store path, so switch-to-configuration
      # can't see a package bump from the unit alone without this.
      restartTriggers = [ cfg.package ];

      path = with pkgs; [ iproute2 iptables procps net-tools ];

      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "root";
        ExecStart = "/opt/happ/bin/happd";
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStopSec = "10s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };
    };
  };
}
