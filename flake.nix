{
  description = "ChipLang - A simple, modular scripting language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chip-go = {
      url = "git+https://codeberg.org/ideumi/chip-go";
      flake = false;
    };
    boxflinger = {
      url = "git+https://codeberg.org/ideumi/boxflinger";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, chip-go, boxflinger }:
    let
      # Support common Linux systems
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      version = "1.0.9";
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = self.packages.${system}.chiplang;
          
          chiplang = pkgs.buildGoModule rec {
            pname = "chiplang";
            inherit version;
            
            src = chip-go;
            
            # Apply patches for CHIP_LIB_PATH support
            patches = [
              ./patches/0001-add-path-resolver-utility.patch
              ./patches/0002-patch-load-function-for-CHIP_LIB_PATH.patch
              ./patches/0003-patch-combine-command-for-CHIP_LIB_PATH.patch
            ];
            
            # Go module vendoring hash
            # To update: set to empty string "", run `nix build`, 
            # and copy the hash from the error message
            vendorHash = "sha256-Mqi9GMz7cRSmg7O/DB8IivoWkA9lHfE8gSDzLohUigY=";
            
            # Use proxy vendor to handle incomplete go.mod
            proxyVendor = true;
            
            # Exclude generator packages that have extra dependencies
            excludedPackages = [
              "thirdparty/uax29/internal/gen"
              "thirdparty/runewidth/script"
            ];
            
            # Build only the chippy binary
            subPackages = [ "cmd/chippy" ];
            
            # Install additional files beyond the binary
            postInstall = ''
              # Install standard library files
              mkdir -p $out/lib/chiplang
              cp -r $src/lib/*.chh $out/lib/chiplang/
              
              # Install documentation files
              mkdir -p $out/share/doc/chiplang
              cp -r doc/*.chpdoc $out/share/doc/chiplang/
            '';
            
            meta = with pkgs.lib; {
              description = "ChipLang (Chipmunk language) - Small interpreted programming language for scripting and tooling";
              longDescription = ''
                ChipLang is an interpreted scripting/programming language written in Go.
                It aims to create a simple, modular, low profile, understandable and 
                hackable programming language for scripting and tooling that would be 
                hard to write, maintain, architect and deploy in shell.
              '';
              homepage = "https://codeberg.org/ideumi/chip-go";
              license = licenses.bsd2;
              maintainers = [ ];
              mainProgram = "chippy";
              platforms = platforms.linux;
            };
          };
          
          chiplang-nvim = pkgs.vimUtils.buildVimPlugin {
            pname = "chiplang-nvim";
            inherit version;
            src = chip-go;
            
            # Restructure to vim plugin format (syntax/ and ftdetect/ at root)
            postInstall = ''
              # Move vim syntax files to plugin root
              mkdir -p $out/syntax $out/ftdetect
              cp $src/ide/vim/syntax/chiplang.vim $out/syntax/
              cp $src/ide/vim/ftdetect/chiplang.vim $out/ftdetect/
              
              # Remove everything else
              find $out -mindepth 1 -maxdepth 1 \
                ! -name 'syntax' \
                ! -name 'ftdetect' \
                -exec rm -rf {} +
            '';
            
            meta = with pkgs.lib; {
              description = "Neovim syntax highlighting for ChipLang";
              homepage = "https://codeberg.org/ideumi/chip-go";
              license = licenses.bsd2;
              platforms = platforms.linux;
            };
          };
          
          boxflinger = pkgs.stdenv.mkDerivation {
            pname = "chiplang-boxflinger";
            version = "1.0.1";
            
            src = boxflinger;
            
            nativeBuildInputs = [ self.packages.${system}.chiplang ];
            
            buildPhase = ''
              # Set environment so chippy can find standard libraries
              export CHIP_LIB_PATH="${self.packages.${system}.chiplang}/lib/chiplang"
              export CHIP_DOC_DIR="${self.packages.${system}.chiplang}/share/doc/chiplang"
              
              # Create output directory
              mkdir -p out
              
              # Run chippy combine to build the library
              chippy combine
            '';
            
            installPhase = ''
              mkdir -p $out/lib/chiplang
              cp out/libboxflinger.chh $out/lib/chiplang/
            '';
            
            meta = with pkgs.lib; {
              description = "Boxflinger - A simple terminal UI library for ChipLang";
              longDescription = ''
                Boxflinger provides terminal UI widgets and drawing primitives for ChipLang,
                including text input, menus, lists, radio buttons, checkboxes, sliders,
                progress bars, and layout management.
              '';
              homepage = "https://codeberg.org/ideumi/boxflinger";
              license = licenses.bsd2;
              platforms = platforms.linux;
            };
          };
        });
      
      # Development shell with Neovim integration
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          chiplangPkg = self.packages.${system}.chiplang;
          chiplangNvim = self.packages.${system}.chiplang-nvim;
          boxflingerPkg = self.packages.${system}.boxflinger;
        in
        {
          default = pkgs.mkShell {
            name = "chip-go-dev";
            
            buildInputs = with pkgs; [
              go
              gopls
              chiplangPkg
            ];
            
            shellHook = ''
              echo "🐿️  ChipLang Development Environment v${version}"
              echo ""
              echo "  ChipLang: ${chiplangPkg}/bin/chippy"
              echo "  Libraries: ${chiplangPkg}/lib/chiplang"
              echo "  Documentation: ${chiplangPkg}/share/doc/chiplang"
              echo ""
              
              # Make Neovim auto-discover ChipLang syntax
              # Add the plugin to Neovim's runtime path
              export VIMINIT="set runtimepath+=${chiplangNvim}"
              
              # Set ChipLang environment variables
              export CHIP_LIB_PATH="${chiplangPkg}/lib/chiplang:${boxflingerPkg}/lib/chiplang"
              export CHIP_DOC_DIR="${chiplangPkg}/share/doc/chiplang"
              
              echo "✓ Neovim configured for .chp and .chh syntax highlighting"
              echo "  (Set via VIMINIT environment variable)"
              echo "✓ Boxflinger terminal UI library available"
              echo ""
            '';
          };
        });
      
      # NixOS module for system-wide installation
      nixosModules.default = import ./module.nix;
      
      # Overlay for integrating into existing configurations
      overlays.default = final: prev: {
        chiplang = self.packages.${final.system}.chiplang;
        chiplang-boxflinger = self.packages.${final.system}.boxflinger;
      };
    };
}
