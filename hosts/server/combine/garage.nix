{ pkgs, ... }: {
  users.users = {
    garage = {
      isSystemUser = true;
      group = "garage";
    };
  };

  users.groups.garage = {};

  systemd.tmpfiles.rules = [
    "d /srv/s3/meta 0700 garage garage -"
    "d /srv/s3/data 0700 garage garage -"
  ];

  services.garage = {
    enable = true;
    settings = {
      metadata_dir = "/srv/s3/meta";
      data_dir = "/srv/s3/data";

      "rpc_bind_addr" = "[::]:3901";
      "rpc_public_addr" = "127.0.0.1:3901";

      "s3_web" = {
        "bind_addr" = "[::]:3902";
        "index" = "index.html";
        "root_domain" = ".web.ar-iss.net";
      };

      "s3_api" = {
        "s3_region" = "garage";
        "api_bind_addr" = "[::]:3900";
        "root_domain" = ".s3.ar-iss.net";
      };

      "admin" = {
        "api_bind_addr" = "[::]:3903";
      };
    };

    package = pkgs.garage;
  };

  systemd.services.garage.serviceConfig = {
    DynamicUser = false;
    User = "garage";
    Group = "garage";
  };
}
