{ pkgs, packages, module }:

let
  lib = pkgs.lib;

  evalModule =
    settings:
    import "${pkgs.path}/nixos/lib/eval-config.nix" {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        module
        (settings // { system.stateVersion = "26.05"; })
      ];
    };

  moduleEval = evalModule {
    programs.chippy.enable = true;
    programs.chippy.boxflinger.enable = true;
  };

  # The pre-rename option paths must keep producing the same wiring.
  legacyModuleEval = evalModule {
    programs.chiplang.enable = true;
    programs.chiplang.boxflinger.enable = true;
  };

  expectedLibPath = "${packages.chippy}/lib/chippy:${packages.chippy-boxflinger}/lib/chippy";
  expectedDocPath = "${packages.chippy}/share/doc/chippy";
  systemPackagePaths = builtins.toJSON (map (pkg: pkg.outPath) moduleEval.config.environment.systemPackages);
  sessionVariables = builtins.toJSON moduleEval.config.environment.sessionVariables;
  legacySessionVariables = builtins.toJSON legacyModuleEval.config.environment.sessionVariables;
in
{
  chippy-smoke = pkgs.runCommand "chippy-smoke" {
    nativeBuildInputs = [ packages.chippy ];
  } ''
    export HOME="$TMPDIR"
    export CHIP_LIB_PATH="${packages.chippy}/lib/chippy"
    export CHIP_DOC_DIR="${packages.chippy}/share/doc/chippy"

    ${packages.chippy}/bin/chippy ${../tests/chippy/main.chp} > output.txt

    grep -F "Chippy Nix Package Test" output.txt
    grep -F "=========================" output.txt
    touch "$out"
  '';

  chippy-nvim-layout = pkgs.runCommand "chippy-nvim-layout" {} ''
    test -f "${packages.chippy-nvim}/syntax/chippy.vim"
    test -f "${packages.chippy-nvim}/ftdetect/chippy.vim"
    touch "$out"
  '';

  chippy-boxflinger-layout = pkgs.runCommand "chippy-boxflinger-layout" {} ''
    test -f "${packages.chippy-boxflinger}/lib/chippy/libboxflinger.chh"
    touch "$out"
  '';

  # The compatibility aliases must resolve to the renamed packages.
  chippy-legacy-aliases = pkgs.runCommand "chippy-legacy-aliases" {} ''
    test "${packages.chiplang}" = "${packages.chippy}"
    test "${packages.chiplang-nvim}" = "${packages.chippy-nvim}"
    test "${packages.chiplang-boxflinger}" = "${packages.chippy-boxflinger}"
    test "${packages.boxflinger}" = "${packages.chippy-boxflinger}"
    touch "$out"
  '';

  depthfinder-layout = pkgs.runCommand "depthfinder-layout" {} ''
    test -f "${packages.depthfinder}/bin/dfn"
    touch "$out"
  '';

  dfn-mounter-layout = pkgs.runCommand "dfn-mounter-layout" {} ''
    test -f "${packages.dfn-mounter}/bin/dfn-mounter"
    test -f "${packages.dfn-mounter}/libexec/dfn-mounter/dfn-mounter.chp"
    touch "$out"
  '';

  nixos-module-eval = pkgs.runCommand "nixos-module-eval" {
    inherit systemPackagePaths sessionVariables;
  } ''
    printf '%s' "$systemPackagePaths" | grep -F '"${packages.chippy}"'
    printf '%s' "$sessionVariables" | grep -F '"CHIP_DOC_DIR":"${expectedDocPath}"'
    printf '%s' "$sessionVariables" | grep -F '"CHIP_LIB_PATH":"${expectedLibPath}"'
    touch "$out"
  '';

  nixos-module-renamed-options = pkgs.runCommand "nixos-module-renamed-options" {
    inherit sessionVariables legacySessionVariables;
  } ''
    test "$legacySessionVariables" = "$sessionVariables"
    touch "$out"
  '';
}
