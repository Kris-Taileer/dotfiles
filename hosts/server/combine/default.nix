{ pkgs, ... }: {
  security.sudo.wheelNeedsPassword = false;

  age.secrets.combine_keys.file = ../../../secrets/combine_keys.age;

  imports = [
    ./garage.nix
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
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
    settings.server = {
      http_addr = "127.0.0.1";
      http_port = 3000;
      enforce_domain = true;
      enable_gzip = true;
    };
  };
}
