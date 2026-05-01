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

  outputs = inputs@{ self, nixpkgs, chip-go, boxflinger }:
    let
      lib = nixpkgs.lib;
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      forEachLinuxSystem = lib.genAttrs linuxSystems;

      versions = {
        chiplang = "1.0.16";
        boxflinger = "1.0.1";
      };

      makePackages = pkgs: import ./pkgs {
        inherit pkgs chip-go versions;
        boxflingerSrc = boxflinger;
      };
    in
    {
      packages = forEachLinuxSystem (system: makePackages nixpkgs.legacyPackages.${system});

      devShells = forEachLinuxSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          packages = self.packages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "chiplang-dev";

            buildInputs = with pkgs; [
              go
              gopls
              packages.chiplang
              packages.chiplang-boxflinger
            ];

            shellHook = ''
              echo "ChipLang development environment v${versions.chiplang}"
              echo "  ChipLang: ${packages.chiplang}/bin/chippy"
              echo "  Libraries: ${packages.chiplang}/lib/chiplang"
              echo "  Documentation: ${packages.chiplang}/share/doc/chiplang"

              export CHIP_LIB_PATH="${packages.chiplang}/lib/chiplang:${packages.chiplang-boxflinger}/lib/chiplang"
              export CHIP_DOC_DIR="${packages.chiplang}/share/doc/chiplang"
            '';
          };
        });

      checks = forEachLinuxSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          packages = self.packages.${system};
        in
        import ./checks {
          inherit pkgs packages;
          module = self.nixosModules.default;
        });

      nixosModules.default = import ./module.nix self;

      overlays.default = final: prev:
        let
          packages = makePackages final;
        in
        {
          inherit (packages) chiplang chiplang-nvim chiplang-boxflinger boxflinger;
        };
    };
}
