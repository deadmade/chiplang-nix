flake:
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.chiplang;
  flakePackages = flake.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.programs.chiplang = {
    enable = lib.mkEnableOption "ChipLang scripting language";

    package = lib.mkOption {
      type = lib.types.package;
      default = flakePackages.chiplang;
      defaultText = lib.literalExpression "chiplang-nix.packages.\${pkgs.system}.chiplang";
      description = ''
        ChipLang package to install and expose through the runtime environment.
      '';
    };

    extraLibraryPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/etc/chiplang/lib";
      description = ''
        Extra library search path appended to `CHIP_LIB_PATH`.
      '';
    };

    boxflinger = {
      enable = lib.mkEnableOption "the Boxflinger terminal UI library for ChipLang";

      package = lib.mkOption {
        type = lib.types.package;
        default = flakePackages.chiplang-boxflinger;
        defaultText = lib.literalExpression "chiplang-nix.packages.\${pkgs.system}.chiplang-boxflinger";
        description = ''
          Boxflinger package to add to the ChipLang library search path.
        '';
      };
    };

    dfn-mounter = {
      enable = lib.mkEnableOption "the dfn-mounter TUI disk mounter";

      package = lib.mkOption {
        type = lib.types.package;
        default = flakePackages.dfn-mounter;
        defaultText = lib.literalExpression "chiplang-nix.packages.\${pkgs.system}.dfn-mounter";
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
      programs.chiplang.dfn-mounter is enabled but services.udisks2.enable is not set.
      dfn-mounter needs the udisks2 daemon (and lsblk) at runtime to mount, unmount,
      unlock, and power off devices. Set services.udisks2.enable = true;
    '';

    environment.sessionVariables =
      let
        libraryPaths =
          [ "${cfg.package}/lib/chiplang" ]
          ++ lib.optional cfg.boxflinger.enable "${cfg.boxflinger.package}/lib/chiplang"
          ++ lib.optional (cfg.extraLibraryPath != null) cfg.extraLibraryPath;
      in
      {
        CHIP_LIB_PATH = lib.concatStringsSep ":" libraryPaths;
        CHIP_DOC_DIR = "${cfg.package}/share/doc/chiplang";
      };
  };

  meta.maintainers = [ ];
}
