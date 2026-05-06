{ config, ... }: {
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
    listenPort = 51820;
    privateKeyFile = config.age.secrets.combine_wg_priv.path;

    extraOptions = {
      Jc = 5;
      Jmin = 50;
      Jmax = 1000;
      S1 = 42;
      S2 = 77;
      H1 = "1500000000-2000000000";
      H2 = "3000000000-3500000000";
      H3 = "2500000000-3000000000";
      H4 = "700000000-1000000000";
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
