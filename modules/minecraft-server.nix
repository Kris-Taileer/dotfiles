{ config, lib, pkgs, ... }:
let
  cfg = config.services.marcraft;
in
{
  options.services.marcraft = {
    enable = lib.mkEnableOption "modded Minecraft server";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/minecraft";
      description = "Server running directory";
    };

    javaPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jdk21;
      description = "Java package to use";
    };

    jvmFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-Xms2G" "-Xmx4G" "-XX:+UseZGC" ];
      description = "JVM flags passed before -jar";
    };

    serverJar = lib.mkOption {
      type = lib.types.str;
      default = "fabric-server-launch.jar";
      description = "Name of the server jar inside dataDir";
    };

    serverStartCommand = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Override full ExecStart command (runs in WorkingDirectory)";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the server port on the firewall";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 25565;
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.minecraft = {
      isSystemUser = true;
      group = "minecraft";
    };
    users.groups.minecraft = { };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 minecraft minecraft -"
    ];

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;

    systemd.sockets.minecraft-server = {
      socketConfig = {
        ListenFIFO = "/run/minecraft-server/console";
        RuntimeDirectory = "minecraft-server";
        RuntimeDirectoryMode = "0750";
        Service = "minecraft-server.service";
      };
    };

    systemd.services.minecraft-server = {
      description = "Minecraft server (Fabric, modded)";

      # No wantedBy: this service is start-on-demand only, via
      # `systemctl start minecraft-server` — it does not run at boot
      # and (with Restart=on-failure) won't loop if dataDir is empty.
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        User = "minecraft";
        Group = "minecraft";

        WorkingDirectory = cfg.dataDir;

        ExecStart =
          if cfg.serverStartCommand != [ ] then
            lib.escapeShellArgs cfg.serverStartCommand
          else
            lib.escapeShellArgs (
              [ "${cfg.javaPackage}/bin/java" ]
              ++ cfg.jvmFlags
              ++ [
                "-jar"
                "${cfg.dataDir}/${cfg.serverJar}"
                "nogui"
              ]
            );

        Restart = "on-failure";
        RestartSec = "30s";

        PrivateTmp = true;
        NoNewPrivileges = true;

        Sockets = [ "minecraft-server.socket" ];
        StandardInput = "socket";

        StandardOutput = "journal";
        StandardError = "journal";

        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.dataDir ];
      };
    };
  };
}
