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
  };

  config = mkIf cfg.enable {
    # Add chippy to system packages
    environment.systemPackages = [ cfg.package ];
    
    # Set environment variables
    environment.sessionVariables = {
      # Library search path for load() builtin (colon-separated)
      CHIP_LIB_PATH = 
        if cfg.extraLibraryPath != null
        then "${cfg.package}/lib/chiplang:${cfg.extraLibraryPath}"
        else "${cfg.package}/lib/chiplang";
      
      # Documentation path for chippy doc
      CHIP_DOC_DIR = "${cfg.package}/share/doc/chiplang";
    };
  };

  meta = {
    maintainers = with lib.maintainers; [ ];
    doc = ./README.md;
  };
}
