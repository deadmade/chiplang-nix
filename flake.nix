{
  description = "ChipLang - A simple, modular scripting language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chip-go = {
      url = "git+https://codeberg.org/ideumi/chip-go";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, chip-go }:
    let
      # Support common Linux systems
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
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
            version = "1.0.7";
            
            src = chip-go;
            
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
              # Install standard library files (from original source)
              mkdir -p $out/lib/chiplang
              cp -r $src/lib/*.chh $out/lib/chiplang/
              
              # Install documentation files (from patched source in PWD)
              mkdir -p $out/share/doc/chiplang
              cp -r doc/*.chpdoc $out/share/doc/chiplang/
              
              # Install IDE syntax files for user reference
              mkdir -p $out/share/chiplang/ide
              cp -r $src/ide/* $out/share/chiplang/ide/
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
        });
      
      # NixOS module for system-wide installation
      nixosModules.default = import ./module.nix;
      
      # Overlay for integrating into existing configurations
      overlays.default = final: prev: {
        chiplang = self.packages.${final.system}.chiplang;
      };
    };
}
