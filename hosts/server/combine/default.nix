{ config, ... }:
{
  age.secrets.combine_garage_keys.file = ../../../secrets/combine_garage_keys.age;
  age.secrets.combine_grafana_secret = {
    file = ../../../secrets/combine_grafana_secret.age;
    owner = "grafana";
  };

  imports = [
    ./garage.nix
  ];

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
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        enable_gzip = true;
      };
      security = {
        secret_key = "$__file{${config.age.secrets.combine_grafana_secret.path}}";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 9000 ];
}
