# modules/couchdb.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.couchdb-sync;
in
{
  options.services.couchdb-sync = {
    enable = lib.mkEnableOption "CouchDB for Obsidian LiveSync";

    adminPassword = lib.mkOption {
      type = lib.types.str;
      description = "Admin password for CouchDB";
      default = "";
    };
    useTailscale = lib.mkEnableOption "Enable Tailscale for secure access, why not mghm";
  };

  config = lib.mkIf cfg.enable {
    services.couchdb = {
      enable = true;
      extraConfig = ''
        [admins]
        admin = ${cfg.adminPassword}
      '';
      settings = {
        couchdb = {
          database_dir = "/var/lib/couchdb";
          view_index_dir = "/var/lib/couchdb";
          uri_file = "/run/couchdb/couchdb.uri";
        };
        httpd = {
          bind_address = "0.0.0.0";
          port = 5984;
        };
        chttpd = {
          require_valid_user = true;
          enable_cors = true;
          cors_origins = "app://obsidian.md,capacitor://localhost,http://localhost";
          cors_credentials = true;
          cors_methods = "GET, PUT, POST, HEAD, DELETE";
          cors_headers = "accept, authorization, content-type, origin, referer, x-csrf-token";
          max_http_request_size = 4294967296;
        };
      };
    };

    services.tailscale.enable = cfg.useTailscale;

    networking.firewall.allowedTCPPorts =
      if cfg.useTailscale then [] else [ 5984 ];

    warnings = lib.optional (cfg.adminPassword == "")
      "services.couchdb-sync.adminPassword is empty – set a strong password, silly!";
  };
}
