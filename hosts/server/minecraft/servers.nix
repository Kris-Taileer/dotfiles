{ pkgs, ... }: {
  users.users.minecraft = {
    isSystemUser = true;
    group = "minecraft";
  };
  users.groups.minecraft = {};

  systemd.tmpfiles.rules = [
    "d /srv/minecraft/zapusk 0744 minecraft minecraft -"
    "d /srv/minecraft/gtnh 0744 minecraft minecraft -"
    "d /run/marcraft 0750 minecraft minecraft -"
  ];

  # networking.firewall.allowedUDPPorts = [ 24454 ];

  services.marcraft.zapusk = {
    enable = false;

    dataDir = "/srv/minecraft/zapusk";
    javaPackage = pkgs.jdk25;
    jvmFlags = ["-XX:+UseZGC" "-XX:+UseCompactObjectHeaders" "-XX:+UseStringDeduplication"];
    forgeArgsPath = "libraries/net/minecraftforge/forge/1.20.1-47.4.20/unix_args.txt";
    openFirewall = true;
  };

  services.marcraft.gtnh = {
    enable = true;

    dataDir = "/srv/minecraft/gtnh";
    javaPackage = pkgs.jdk25;
    jvmFlags = ["-XX:+UseZGC" "-XX:+UseCompactObjectHeaders" "-XX:+UseStringDeduplication" "-Xms6G" "-Xmx6G" "-Dfml.readTimeout=180" "@java9args.txt"];
    serverJar = "lwjgl3ify-forgePatches.jar";
    openFirewall = true;
  };
}
