{ ... }: {
  users.users.minecraft = {
    isSystemUser = true;
    group = "minecraft";
  };

  users.groups.minecraft = {};

  systemd.tmpfiles.rules = [
    "d /srv/minecraft/zapusk 0744 minecraft minecraft -"
  ];

  services.forgeServer = {
    enable = true;
    dataDir = "/srv/minecraft/zapusk";
  };

  # services.marcraft.zapusk = {

  # };
}
