{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.chiplang;
in
{
  options.programs.chiplang = {
    enable = mkEnableOption "ChipLang scripting language";

    package = mkOption {
      type = types.package;
      default = pkgs.chiplang;
      defaultText = literalExpression "pkgs.chiplang";
      description = ''
        The ChipLang package to use.
      '';
    };

    extraLibraryPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/etc/chiplang/lib";
      description = ''
        Additional library search path for ChipLang scripts.
        This path will be appended to CHIP_LIB_PATH, allowing you to
        provide custom libraries alongside the system libraries.
      '';
    };

    boxflinger = {
      enable = mkEnableOption "Boxflinger terminal UI library for ChipLang";

      package = mkOption {
        type = types.package;
        default = pkgs.chiplang-boxflinger;
        defaultText = literalExpression "pkgs.chiplang-boxflinger";
        description = ''
          The Boxflinger package to use.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Add chippy to system packages
    environment.systemPackages = [ cfg.package ];
    
    # Set environment variables
    environment.sessionVariables = {
      # Library search path for load() builtin (colon-separated)
      CHIP_LIB_PATH = 
        let
          basePath = "${cfg.package}/lib/chiplang";
          boxflingerPath = optionalString cfg.boxflinger.enable 
            ":${cfg.boxflinger.package}/lib/chiplang";
          extraPath = optionalString (cfg.extraLibraryPath != null) 
            ":${cfg.extraLibraryPath}";
        in
          basePath + boxflingerPath + extraPath;
      
      # Documentation path for chippy doc
      CHIP_DOC_DIR = "${cfg.package}/share/doc/chiplang";
    };
  };

  meta = {
    maintainers = with lib.maintainers; [ ];
    doc = ./README.md;
  };
}
