{ settings, ... }: {
  virtualisation.docker.enable = true;

  users.users.${settings.username}.extraGroups = [ "docker" ];
}
