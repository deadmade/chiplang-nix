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
        This path will be available via the CHIP_LIB_DIR environment variable.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Add chippy to system packages
    environment.systemPackages = [ cfg.package ];
    
    # Set environment variables for convenience
    environment.sessionVariables = mkMerge [
      {
        # Point to the Nix store locations
        CHIP_LIB_DIR = "${cfg.package}/lib/chiplang";
        CHIP_DOC_DIR = "${cfg.package}/share/doc/chiplang";
      }
      (mkIf (cfg.extraLibraryPath != null) {
        CHIP_EXTRA_LIB_DIR = cfg.extraLibraryPath;
      })
    ];
  };

  meta = {
    maintainers = with lib.maintainers; [ ];
    doc = ./README.md;
  };
}
