{ pkgs, ... }: {
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  systemd.tmpfiles.rules = [
    "d /srv/s3/meta 0744 root root -"
    "d /srv/s3/data 0744 root root -"
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

  services.prometheus = {
    enable = true;
    port = 9000;

    globalConfig.scrape_interval = "10s"; # "1m"
    scrapeConfigs = [
      {
        job_name = "s3";
        static_configs = [{
          targets = [ "localhost:3903" ];
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = "127.0.0.1";
      http_port = 3000;
      enforce_domain = true;
      enable_gzip = true;
    };
  };
}
