{ config, lib, pkgs, ... }:

let
  cfg = config.services.marcraft;

  enabledServers = lib.filterAttrs (_: server: server.enable) cfg;

  serverModule = { name, ... }: {
    options = {
      enable = lib.mkEnableOption "Minecraft server";

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/minecraft/${name}";
        description = "Server running directory";
      };

      javaPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.jdk21;
        description = "Java package to use";
      };

      jvmFlags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "-Xms2G"
          "-Xmx4G"
          "-XX:+UseZGC"
        ];
        description = "JVM flags passed before -jar";
      };

      serverJar = lib.mkOption {
        type = lib.types.str;
        default = "server.jar";
        description = "Name of the server jar inside dataDir";
      };

      forgeArgsPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to Forge unix_args.txt relative to dataDir (enables Forge launcher mode)";
      };

      serverStartCommand = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Override full ExecStart command (runs in WorkingDirectory)";
      };

      enableCommandSocket = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable socket for command inputs";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 25565;
      };
    };
  };
in
{
  options.services.marcraft = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule serverModule);
    default = {};
    description = "Named Minecraft server instances";
  };

  config = {
    networking.firewall.allowedTCPPorts =
      lib.concatMap (server:
        lib.optional server.openFirewall server.port
      ) (lib.attrValues enabledServers);

    systemd.sockets =
      lib.mapAttrs' (name: server:
        lib.nameValuePair "minecraft-${name}" (
          lib.optionalAttrs (server.enableCommandSocket) {
            wantedBy = [ "sockets.target" ];

            socketConfig = {
              ListenFIFO = "/run/marcraft/${name}";
              Service = "minecraft-${name}.service";
            };
          }
        )
      ) enabledServers;

    systemd.services =
      lib.mapAttrs' (name: server:
        lib.nameValuePair "minecraft-${name}" {
          description = "Minecraft Server (${name})";

          wantedBy = [ "multi-user.target" ];

          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = {
            User = "minecraft";
            Group = "minecraft";

            WorkingDirectory = server.dataDir;

            ExecStart =
              if server.serverStartCommand != [] then
                lib.escapeShellArgs server.serverStartCommand
              else if server.forgeArgsPath != null && server.forgeArgsPath != "" then
                lib.escapeShellArgs (
                  [ "${server.javaPackage}/bin/java" ]
                  ++ server.jvmFlags
                  ++ [
                    "@${server.forgeArgsPath}"
                  ]
                )
              else
                lib.escapeShellArgs (
                  [ "${server.javaPackage}/bin/java" ]
                  ++ server.jvmFlags
                  ++ [
                    "-jar"
                    "${server.dataDir}/${server.serverJar}"
                    "nogui"
                  ]
                );

            Restart = "on-failure";
            RestartSec = "30s";

            PrivateTmp = true;
            NoNewPrivileges = true;

            StandardInput =
              if server.enableCommandSocket then "socket" else null;
            RuntimeDirectory = "marcraft";
            RuntimeDirectoryMode = "0750";

            StandardOutput = "journal";
            StandardError = "journal";
            ProtectSystem = "strict";
            ReadWritePaths = [ server.dataDir ];
          };
        }
      ) enabledServers;
  };
}
