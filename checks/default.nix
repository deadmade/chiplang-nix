{ pkgs, packages, module }:

let
  lib = pkgs.lib;

  moduleEval = import "${pkgs.path}/nixos/lib/eval-config.nix" {
    system = pkgs.stdenv.hostPlatform.system;
    modules = [
      module
      {
        programs.chiplang.enable = true;
        programs.chiplang.boxflinger.enable = true;
        system.stateVersion = "26.05";
      }
    ];
  };

  expectedLibPath = "${packages.chiplang}/lib/chiplang:${packages.chiplang-boxflinger}/lib/chiplang";
  expectedDocPath = "${packages.chiplang}/share/doc/chiplang";
  systemPackagePaths = builtins.toJSON (map (pkg: pkg.outPath) moduleEval.config.environment.systemPackages);
  sessionVariables = builtins.toJSON moduleEval.config.environment.sessionVariables;
in
{
  chiplang-smoke = pkgs.runCommand "chiplang-smoke" {
    nativeBuildInputs = [ packages.chiplang ];
  } ''
    export HOME="$TMPDIR"
    export CHIP_LIB_PATH="${packages.chiplang}/lib/chiplang"
    export CHIP_DOC_DIR="${packages.chiplang}/share/doc/chiplang"

    ${packages.chiplang}/bin/chippy ${../tests/chippy/main.chp} > output.txt

    grep -F "ChipLang Nix Package Test" output.txt
    grep -F "=========================" output.txt
    touch "$out"
  '';

  chiplang-nvim-layout = pkgs.runCommand "chiplang-nvim-layout" {} ''
    test -f "${packages.chiplang-nvim}/syntax/chiplang.vim"
    test -f "${packages.chiplang-nvim}/ftdetect/chiplang.vim"
    touch "$out"
  '';

  chiplang-boxflinger-layout = pkgs.runCommand "chiplang-boxflinger-layout" {} ''
    test -f "${packages.chiplang-boxflinger}/lib/chiplang/libboxflinger.chh"
    touch "$out"
  '';

  depthfinder-layout = pkgs.runCommand "depthfinder-layout" {} ''
    test -f "${packages.depthfinder}/bin/dfn"
    touch "$out"
  '';

  nixos-module-eval = pkgs.runCommand "nixos-module-eval" {
    inherit systemPackagePaths sessionVariables;
  } ''
    printf '%s' "$systemPackagePaths" | grep -F '"${packages.chiplang}"'
    printf '%s' "$sessionVariables" | grep -F '"CHIP_DOC_DIR":"${expectedDocPath}"'
    printf '%s' "$sessionVariables" | grep -F '"CHIP_LIB_PATH":"${expectedLibPath}"'
    touch "$out"
  '';
}
