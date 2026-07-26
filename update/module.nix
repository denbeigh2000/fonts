{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.denbeigh.services.updaters.fonts;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in

{
  options.denbeigh.services.updaters.fonts = {
    enable = mkEnableOption "Font updating daemon";

    sshKeyPath = mkOption {
      type = types.path;
      description = ''
        Path to the SSH key to use for authentication.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "denbeigh-font-updater";
      description = ''
        User to run the job as.
      '';
    };

    calendar = mkOption {
      type = types.str;
      default = "00/6:15:00";
      description = ''
        Calendar expression to execute checks on (default every 6 hours)
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./. { };
      defaultText = lib.literalExpression "pkgs.callPackage ./. { }";
      description = ''
        The update-tool package to use. Defaults to the version bundled with
        this module.
      '';
    };
  };

  config = (
    mkIf cfg.enable {
      users = {
        users.${cfg.user} = {
          isSystemUser = true;
          group = cfg.user;
        };

        groups.${cfg.user} = { };
      };

      systemd.services.denbeigh-font-updater = {
        description = "Check for updates in public font repo.";

        script = ''
          set -euo pipefail

          FONT_SSH_KEY="${cfg.sshKeyPath}" FONT_CHECKOUT_DIR="$STATE_DIRECTORY" ${cfg.package}/bin/update
        '';

        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.user;
          StateDirectory = "./denbeigh-font-updater";
          StateDirectoryMode = "750";
          Environment = [
            "LOG_LEVEL=info"
          ];
        };
      };

      systemd.timers.denbeigh-font-updater = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.calendar;
          Persistent = true;
        };
      };
    }
  );
}
