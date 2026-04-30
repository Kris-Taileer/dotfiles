{ pkgs, ... }: {
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    javaPackages.compiler.temurin-bin.jdk-25
    vim
    git
  ];

  services.garage = {
    enable = true;
    settings.metadata_dir = "/srv/s3/meta";
    settings.data_dir = "/srv/s3/data";
    package = pkgs.garage;
  };

  services.prometheus = {
    enable = true;
    port = 9000;
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
