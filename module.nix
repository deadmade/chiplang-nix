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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

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
