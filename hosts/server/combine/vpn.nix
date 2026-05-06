{ config, ... }: {
  age.secrets.combine_wg_priv.file = ../../../secrets/combine_wg_priv.age;

  nixpkgs.overlays = [
    (final: prev: {
      amneziawg-tools = prev.amneziawg-tools.overrideAttrs (_: {
        version = "1.0.20260223";
        src = prev.fetchFromGitHub {
          owner = "amnezia-vpn";
          repo = "amneziawg-tools";
          rev = "5d6179a6d0842e98dfb349c28cf1bd8e4b9d1079";
          hash = "sha256-pHmuxlrbTqjwRrB7BShdC4ENw3iVQRRLH+Z2w8x+KeE=";
        };
      });

      linuxPackages = prev.linuxPackages.extend (_lfinal: lprev: {
        amneziawg = lprev.amneziawg.overrideAttrs (_: {
          version = "1.0.20260329-2";
          src = prev.fetchFromGitHub {
            owner = "amnezia-vpn";
            repo = "amneziawg-linux-kernel-module";
            rev = "ac8e22c264f5309ff4bdcfde0f6ddc4076201aa9";
            hash = "sha256-csKb8xFnsOYnIbnoqbpIY/R7X8OqF9O9pKC/JZH42pA=";
          };
        });
      });
    })
  ];

  networking.firewall.allowedUDPPorts = [ 51820 ];

  networking.wg-quick.interfaces.awg0 = {
    type = "amneziawg";
    address = [ "10.0.0.1/24" ];
    listenPort = 46739;
    privateKeyFile = config.age.secrets.combine_wg_priv.path;

    extraOptions = {
      Jc = 4;
      Jmin = 10;
      Jmax = 50;
      S1 = 35;
      S2 = 19;
      S3 = 4;
      S4 = 10;
      H1 = "967323192-1006321317";
      H2 = "1592923576-1779923104";
      H3 = "1897984490-2083842647";
      H4 = "2091981620-2139103456";
    };

    peers = [{
      publicKey = "VeU3dauI19A2dWsZWLhrDDSv58Y2RlZkh23AZBye7Fg=";
      allowedIPs = [ "10.0.0.2/32" ];
    }];
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "awg0" ];
    externalInterface = "ens34";
  };

  boot.extraModulePackages = [ config.boot.kernelPackages.amneziawg ];
  boot.kernelModules = [ "amneziawg" ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}
