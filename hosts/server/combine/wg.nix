{ pkgs, config, ... }: {
  age.secrets.combine_wg_privkey.file = ../../../secrets/combine_wg_privkey.age;
  environment.systemPackages = [
    pkgs.wireguard-tools
  ];

  networking.firewall.allowedUDPPorts = [ 51820 ];
  networking.wireguard.interfaces.wg-cluster = {
    ips = [ "10.14.88.1/24" ];
    listenPort = 51820;
    privateKeyFile = config.age.secrets.combine_wg_privkey.path;

    peers = [];
  };
}
