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

    peers = [
      {
        publicKey = "AVc11dZBMnZ2yNZrpE4FHAZvsLEYueMFpqjSgOIrWm0=";
        allowedIPs = [ "10.14.88.10/32" ];
        persistentKeepalive = 25;
      }
      {
        publicKey = "MoBwYmHSNk0E7sq3uszzQhsWsWLswwxUfPOw5SKnT2U=";
        allowedIPs = [ "10.14.88.11/32" ];
        persistentKeepalive = 25;
      }
      {
        publicKey = "IkhueWfI6nAu3Sw7JUk9XcV6YcBvDRR+qSUFqL/B6BU=";
        allowedIPs = [ "10.14.88.12/32" ];
        persistentKeepalive = 25;
      }
      {
        publicKey = "UGdhmPQc9Ru5J8fwOYYaqo4WuM4kZLCkutkOD2yBkgA=";
        allowedIPs = [ "10.14.88.13/32" ];
        persistentKeepalive = 25;
      }
      {
        publicKey = "cau/2DE3mvuTFTOxcOOaBqWf+QVPF0GOWT+7q8qsPyg=";
        allowedIPs = [ "10.14.88.14/32" ];
        persistentKeepalive = 25;
      }
    ];
  };
}
