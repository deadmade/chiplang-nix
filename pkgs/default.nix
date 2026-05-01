{ pkgs, chip-go, boxflingerSrc, versions }:

let
  lib = pkgs.lib;
in
rec {
  chiplang = pkgs.buildGoModule {
    pname = "chiplang";
    version = versions.chiplang;

    src = chip-go;

    patches = [
      ../patches/0001-add-path-resolver-utility.patch
      ../patches/0002-patch-load-function-for-CHIP_LIB_PATH.patch
      ../patches/0003-patch-combine-command-for-CHIP_LIB_PATH.patch
    ];

    vendorHash = "sha256-Mqi9GMz7cRSmg7O/DB8IivoWkA9lHfE8gSDzLohUigY=";
    proxyVendor = true;

    excludedPackages = [
      "thirdparty/uax29/internal/gen"
      "thirdparty/runewidth/script"
    ];

    subPackages = [ "cmd/chippy" ];

    postInstall = ''
      mkdir -p $out/lib/chiplang
      cp -r $src/lib/*.chh $out/lib/chiplang/

      mkdir -p $out/share/doc/chiplang
      cp -r doc/*.chpdoc $out/share/doc/chiplang/
    '';

    meta = {
      description = "ChipLang (Chipmunk language) interpreter with standard library and docs";
      longDescription = ''
        ChipLang is an interpreted scripting/programming language written in Go.
        It focuses on a small, modular, understandable runtime for scripting and
        tooling that would be awkward to build and maintain in shell.
      '';
      homepage = "https://codeberg.org/ideumi/chip-go";
      license = lib.licenses.bsd2;
      mainProgram = "chippy";
      platforms = lib.platforms.linux;
    };
  };

  chiplang-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "chiplang-nvim";
    version = versions.chiplang;
    src = chip-go;

    postInstall = ''
      mkdir -p $out/syntax $out/ftdetect
      cp $src/ide/vim/syntax/chiplang.vim $out/syntax/
      cp $src/ide/vim/ftdetect/chiplang.vim $out/ftdetect/

      find $out -mindepth 1 -maxdepth 1 \
        ! -name 'syntax' \
        ! -name 'ftdetect' \
        -exec rm -rf {} +
    '';

    meta = {
      description = "Vim and Neovim syntax highlighting for ChipLang";
      homepage = "https://codeberg.org/ideumi/chip-go";
      license = lib.licenses.bsd2;
      platforms = lib.platforms.all;
    };
  };

  chiplang-boxflinger = pkgs.stdenv.mkDerivation {
    pname = "chiplang-boxflinger";
    version = versions.boxflinger;

    src = boxflingerSrc;

    nativeBuildInputs = [ chiplang ];

    buildPhase = ''
      export CHIP_LIB_PATH="${chiplang}/lib/chiplang"
      export CHIP_DOC_DIR="${chiplang}/share/doc/chiplang"

      mkdir -p out
      chippy combine
    '';

    installPhase = ''
      mkdir -p $out/lib/chiplang
      cp out/libboxflinger.chh $out/lib/chiplang/
    '';

    meta = {
      description = "Boxflinger terminal UI library for ChipLang";
      longDescription = ''
        Boxflinger provides terminal UI widgets and drawing primitives for ChipLang,
        including text input, menus, lists, radio buttons, checkboxes, sliders,
        progress bars, and layout management.
      '';
      homepage = "https://codeberg.org/ideumi/boxflinger";
      license = lib.licenses.bsd2;
      platforms = lib.platforms.linux;
    };
  };

  boxflinger = chiplang-boxflinger;
  default = chiplang;
}
