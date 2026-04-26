{ pkgs, settings, ... }: {
  virtualisation.docker.enable = true;

  users.users.${settings.username}.extraGroups = [ "docker" ];
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}
