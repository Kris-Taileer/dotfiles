{ lib, settings, ... }:
{
  networking.firewall.allowedTCPPorts = [ 23231 ];

  services.soft-serve = {
    enable = true;
    settings = {
      name = "marduk.ru git";

      ssh = {
        public_url = "ssh://marduk.ru";
      };

      lfs = {
        ssh_enabled = true;
      };
      git = {
        enabled = false;
      };
      http = {
        enabled = false;
      };

      initial_admin_keys = [
        (builtins.elemAt settings.sshPubkeys 0)
      ];
    };
  };

  systemd.services.soft-serve.serviceConfig.StateDirectory = lib.mkForce [
    "soft-serve"
    "soft-serve/repos"
  ];
}
