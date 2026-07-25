flake:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.chippy;
  flakePackages = flake.packages.${pkgs.stdenv.hostPlatform.system};

  # programs.chiplang.* was renamed to programs.chippy.*. Keep the old paths
  # working (with a deprecation warning) so existing configurations still eval.
  renamed =
    old: new:
    lib.mkRenamedOptionModule ([ "programs" "chiplang" ] ++ old) ([ "programs" "chippy" ] ++ new);
in
{
  imports = [
    (renamed [ "enable" ] [ "enable" ])
    (renamed [ "package" ] [ "package" ])
    (renamed [ "extraLibraryPath" ] [ "extraLibraryPath" ])
    (renamed [ "boxflinger" "enable" ] [ "boxflinger" "enable" ])
    (renamed [ "boxflinger" "package" ] [ "boxflinger" "package" ])
    (renamed [ "dfn-mounter" "enable" ] [ "dfn-mounter" "enable" ])
    (renamed [ "dfn-mounter" "package" ] [ "dfn-mounter" "package" ])
  ];

  options.programs.chippy = {
    enable = lib.mkEnableOption "Chippy scripting language";

    package = lib.mkOption {
      type = lib.types.package;
      default = flakePackages.chippy;
      defaultText = lib.literalExpression "chippy-nix.packages.\${pkgs.system}.chippy";
      description = ''
        Chippy package to install and expose through the runtime environment.
      '';
    };

    extraLibraryPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/etc/chippy/lib";
      description = ''
        Extra library search path appended to `CHIP_LIB_PATH`.
      '';
    };

    boxflinger = {
      enable = lib.mkEnableOption "the Boxflinger terminal UI library for Chippy";

      package = lib.mkOption {
        type = lib.types.package;
        default = flakePackages.chippy-boxflinger;
        defaultText = lib.literalExpression "chippy-nix.packages.\${pkgs.system}.chippy-boxflinger";
        description = ''
          Boxflinger package to add to the Chippy library search path.
        '';
      };
    };

    dfn-mounter = {
      enable = lib.mkEnableOption "the dfn-mounter TUI disk mounter";

      package = lib.mkOption {
        type = lib.types.package;
        default = flakePackages.dfn-mounter;
        defaultText = lib.literalExpression "chippy-nix.packages.\${pkgs.system}.dfn-mounter";
        description = ''
          dfn-mounter package to install. Requires the udisks2 daemon
          (`services.udisks2.enable`) and lsblk at runtime.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [ cfg.package ]
      ++ lib.optional cfg.dfn-mounter.enable cfg.dfn-mounter.package;

    # dfn-mounter shells out to udisksctl, which needs the udisks2 D-Bus daemon
    # running on the host. Warn at nixos-rebuild time if it is not enabled.
    warnings = lib.optional (cfg.dfn-mounter.enable && !config.services.udisks2.enable) ''
      programs.chippy.dfn-mounter is enabled but services.udisks2.enable is not set.
      dfn-mounter needs the udisks2 daemon (and lsblk) at runtime to mount, unmount,
      unlock, and power off devices. Set services.udisks2.enable = true;
    '';

    environment.sessionVariables =
      let
        libraryPaths =
          [ "${cfg.package}/lib/chippy" ]
          ++ lib.optional cfg.boxflinger.enable "${cfg.boxflinger.package}/lib/chippy"
          ++ lib.optional (cfg.extraLibraryPath != null) cfg.extraLibraryPath;
      in
      {
        CHIP_LIB_PATH = lib.concatStringsSep ":" libraryPaths;
        CHIP_DOC_DIR = "${cfg.package}/share/doc/chippy";
      };
  };

  meta.maintainers = [ ];
}
