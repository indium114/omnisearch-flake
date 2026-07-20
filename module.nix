self:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.omnisearch;
  pkg = cfg.package;

  finalConfigFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      pkgs.writeText "omnisearch.ini" ''
        [server]
        host = ${cfg.settings.server.host}
        port = ${toString cfg.settings.server.port}
        domain = ${cfg.settings.server.domain}
        ${lib.optionalString (cfg.settings.server.locale != null) "locale = ${cfg.settings.server.locale}"}

        [proxy]
        ${lib.optionalString (cfg.settings.proxy.proxy != null) "proxy = \"${cfg.settings.proxy.proxy}\""}
        ${lib.optionalString (
          cfg.settings.proxy.list_file != null
        ) "list_file = ${cfg.settings.proxy.list_file}"}
        max_retries = ${toString cfg.settings.proxy.max_retries}
        randomize_username = ${lib.boolToString cfg.settings.proxy.randomize_username}
        randomize_password = ${lib.boolToString cfg.settings.proxy.randomize_password}

        [cache]
        dir = ${cfg.settings.cache.dir}
        ttl_search = ${toString cfg.settings.cache.ttl_search}
        ttl_infobox = ${toString cfg.settings.cache.ttl_infobox}
      '';
in
{
  options.services.omnisearch = {
    enable = lib.mkEnableOption "OmniSearch metasearch engine";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "The omnisearch package to use.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a custom config.ini. Overrides 'settings'.";
    };

    settings = {
      server = {
        host = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 8087;
        };
        domain = lib.mkOption {
          type = lib.types.str;
          default = "http://localhost:${toString cfg.settings.server.port}";
        };
        locale = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };
      proxy = {
        proxy = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        list_file = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        max_retries = lib.mkOption {
          type = lib.types.int;
          default = 3;
        };
        randomize_username = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        randomize_password = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
      cache = {
        dir = lib.mkOption {
          type = lib.types.str;
          default = "/var/cache/omnisearch";
        };
        ttl_search = lib.mkOption {
          type = lib.types.int;
          default = 3600;
        };
        ttl_infobox = lib.mkOption {
          type = lib.types.int;
          default = 86400;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.omnisearch = {
      description = "OmniSearch Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkg}/bin/omnisearch";

        WorkingDirectory = "/var/lib/omnisearch";
        StateDirectory = "omnisearch";
        CacheDirectory = "omnisearch";

        BindReadOnlyPaths = [
          "${pkg}/share/omnisearch/templates:/var/lib/omnisearch/templates"
          "${pkg}/share/omnisearch/static:/var/lib/omnisearch/static"
          "${pkg}/share/omnisearch/locales:/var/lib/omnisearch/locales"
          "${finalConfigFile}:/var/lib/omnisearch/config.ini"
        ];

        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        Restart = "always";
      };
    };
  };
}
